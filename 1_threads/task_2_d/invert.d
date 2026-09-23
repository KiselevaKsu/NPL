import std.stdio;
import std.file;
import std.conv;
import std.format;
import core.thread;
import core.time;

// структура изображения
struct PPMImage
{
    int width;
    int height;
    ubyte[] pixels;  // RGB, 3 байта на пиксель
}

// читаем PPM формата P6 (бинарный)
PPMImage readPPM(string filename)
{
    auto data = cast(ubyte[]) std.file.read(filename);
    size_t pos = 0;

    string magic = cast(string) data[pos .. pos + 2];
    pos += 2;
    if (magic != "P6")
        throw new Exception("Expected P6, got: " ~ magic);

    void skipWhitespace()
    {
        while (pos < data.length &&
               (data[pos] == ' ' || data[pos] == '\n' ||
                data[pos] == '\r' || data[pos] == '\t'))
            pos++;
    }

    int readInt()
    {
        int v = 0;
        while (pos < data.length && data[pos] >= '0' && data[pos] <= '9')
        {
            v = v * 10 + (data[pos] - '0');
            pos++;
        }
        return v;
    }

    skipWhitespace();
    int w = readInt();
    skipWhitespace();
    int h = readInt();
    skipWhitespace();
    int maxval = readInt();
    pos++;  // один символ после maxval

    PPMImage img;
    img.width = w;
    img.height = h;
    img.pixels = data[pos .. pos + w * h * 3].dup;
    return img;
}

// записываем PPM формата P6
void writePPM(string filename, PPMImage img)
{
    auto f = File(filename, "wb");
    f.write("P6\n");
    f.write(format("%d %d\n255\n", img.width, img.height));
    f.rawWrite(img.pixels);
}

// инверсия: 255 - значение
void invertSequential(ubyte[] pixels)
{
    foreach (i; 0 .. pixels.length)
        pixels[i] = cast(ubyte)(255 - cast(int) pixels[i]);
}

// поток, который инвертирует свой кусок массива
class InvertThread : Thread
{
    ubyte[] pix;
    size_t start;
    size_t end;

    this(ubyte[] p, size_t s, size_t e)
    {
        super(&run);
        pix = p;
        start = s;
        end = e;
    }

    void run()
    {
        foreach (i; start .. end)
            pix[i] = cast(ubyte)(255 - cast(int) pix[i]);
    }
}

// параллельная инверсия: делим массив на куски, каждый поток обрабатывает свой
void invertParallel(ubyte[] pixels, int numThreads)
{
    size_t chunk = pixels.length / numThreads;
    auto threads = new Thread[](numThreads);

    foreach (t; 0 .. numThreads)
    {
        size_t start = t * chunk;
        size_t end   = (t == numThreads - 1) ? pixels.length : start + chunk;

        threads[t] = new InvertThread(pixels, start, end);
        threads[t].start();
    }

    foreach (th; threads)
        th.join();
}

void main(string[] args)
{
    if (args.length < 3)
    {
        writeln("Usage: invert <input.ppm> <output.ppm> [threads]");
        return;
    }

    string inputFile  = args[1];
    string outputFile = args[2];
    int numThreads    = (args.length >= 4) ? to!int(args[3]) : 4;

    writeln("Reading: ", inputFile);
    auto img = readPPM(inputFile);
    writeln("Size: ", img.width, "x", img.height,
            ", pixel bytes: ", img.pixels.length);

    auto copy1 = img.pixels.dup;
    auto t0 = MonoTime.currTime;
    invertSequential(copy1);
    auto t1 = MonoTime.currTime;
    auto seqTime = (t1 - t0).total!"usecs";

    auto copy2 = img.pixels.dup;
    t0 = MonoTime.currTime;
    invertParallel(copy2, numThreads);
    t1 = MonoTime.currTime;
    auto parTime = (t1 - t0).total!"usecs";

    bool same = true;
    size_t diffCount = 0;
    size_t firstDiff = 0;
    foreach (i; 0 .. copy1.length)
    {
        if (copy1[i] != copy2[i])
        {
            if (diffCount == 0)
                firstDiff = i;
            diffCount++;
            same = false;
        }
    }

    writeln("---");
    writeln("Sequential: ", seqTime, " usecs");
    writeln("Parallel  : ", parTime, " usecs, threads = ", numThreads);
    writeln("Diff count: ", diffCount, ", first diff at byte: ", firstDiff);
    writeln("Results match: ", same ? "yes" : "NO");

    PPMImage result;
    result.width = img.width;
    result.height = img.height;
    result.pixels = copy2;
    writePPM(outputFile, result);
    writeln("Saved: ", outputFile);
}
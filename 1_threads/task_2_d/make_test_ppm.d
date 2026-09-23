import std.stdio;
import std.format;

void main(string[] args)
{
    int width  = 800;
    int height = 600;
    string filename = (args.length > 1) ? args[1] : "input.ppm";

    auto f = File(filename, "wb");
    f.write("P6\n");
    f.write(format("%d %d\n255\n", width, height));

    foreach (y; 0 .. height)
    {
        foreach (x; 0 .. width)
        {
            ubyte r = cast(ubyte)(x * 255 / (width - 1));
            ubyte g = cast(ubyte)(y * 255 / (height - 1));
            ubyte b = cast(ubyte)(((x + y) * 255) / (width + height - 2));
            f.rawWrite([r, g, b]);
        }
    }
    writeln("File created: ", filename, " (", width, "x", height, ")");
}
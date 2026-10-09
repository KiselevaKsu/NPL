-- поиск файлов по маске с выводом информации и сохранением отчёта

module Main where

import System.Environment (getArgs)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory, getModificationTime, getFileSize)
import System.FilePath ((</>), takeFileName)
import Data.Time.Format (formatTime, defaultTimeLocale)
import Data.List (isSuffixOf, sort, intercalate)
import Control.Monad (forM, filterM)
import Data.Time.Clock (UTCTime)
import System.IO

-- проверяем, подходит ли имя файла под маску вида "*.txt"
matchesMask :: String -> String -> Bool
matchesMask mask name =
    case break (== '*') mask of
        (_, "") -> mask == name
        (prefix, _:suffix) -> prefix `isPrefixOf` name && suffix `isSuffixOf` name
    where
        isPrefixOf p s = take (length p) s == p

-- рекурсивный обход каталога
findFiles :: String -> String -> IO [FilePath]
findFiles dir mask = do
    entries <- listDirectory dir
    let fullPaths = map (dir </>) entries
    files <- filterM doesFileExist fullPaths
    dirs <- filterM doesDirectoryExist fullPaths
    let matching = filter (matchesMask mask . takeFileName) files
    subResults <- forM dirs $ \d -> findFiles d mask
    return (matching ++ concat subResults)

-- форматирование строки отчёта
formatEntry :: FilePath -> Integer -> UTCTime -> String
formatEntry path size mtime =
    let timeStr = formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S" mtime
    in padRight 30 path ++ " | " ++ padLeft 10 (show size) ++ " bytes | " ++ timeStr
  where
    padRight n s = s ++ replicate (max 0 (n - length s)) ' '
    padLeft n s = replicate (max 0 (n - length s)) ' ' ++ s

main :: IO ()
main = do
    args <- getArgs
    case args of
        [dir, mask] -> do
            exists <- doesDirectoryExist dir
            if not exists
                then putStrLn ("Error: directory not found: " ++ dir)
                else do
                    files <- findFiles dir mask
                    let sorted = sort files
                    putStrLn ("Found files: " ++ show (length sorted))
                    entries <- forM sorted $ \f -> do
                        size <- getFileSize f
                        mtime <- getModificationTime f
                        return (formatEntry f size mtime)
                    let report = unlines entries
                    putStr report
                    -- записываем отчёт в файл
                    writeFile "find_report.txt" report
                    putStrLn "Report saved to find_report.txt"
        _ -> putStrLn "Usage: findfiles <directory> <mask>"
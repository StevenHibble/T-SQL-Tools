CREATE FUNCTION [Tools].[GetWords] (@String VARCHAR(8000)) -- DO NOT USE MAX DATA-TYPES HERE!  IT WILL KILL PERFORMANCE!
/*
This function splits a VARCHAR string into a table of words by all non-word characters (defined as Alpha-numeric characters)
The table returns ID (by the order of occurance) and Word (the element)

EXAMPLE: 
SELECT * 
FROM [Tools].[GetWords] ('A sentence, but I only want the words; forget about the punctuation.')
ID | Word
###########
1  | A
2  | sentence
3  | but
4  | I
5  | only
6  | want
7  | the
8  | words
9  | forget
10 | about
11 | the
12 | punctuation

This is based off [Tools].[SplitString], which in turn is based on Jeff Moden's DelimitedSplit8K function: http://www.sqlservercentral.com/articles/Tally+Table/72993/
It has been modified to:
      1) Split on anything that doesn't LIKE-match '[a-zA-Z0-9]'
*/
RETURNS TABLE
WITH SCHEMABINDING
AS
  RETURN
       /* 10 rows (all 1s) */
  WITH [CTE_10]
       AS (SELECT [Number]
           FROM(VALUES (1), (1), (1), (1), (1), (1), (1), (1), (1), (1) ) [v]([Number])),
       -------------------
       /* 100 rows (all 1s) */
       [CTE_100]
       AS (SELECT [Number] = 1
           FROM [CTE_10] [a]
                CROSS JOIN [CTE_10] [b]),
       -------------------
       /* 10000 rows max (all 1s) */
       [CTE_10000]
       AS (SELECT [Number] = 1
           FROM [CTE_100] [a]
                CROSS JOIN [CTE_100] [b]),
       -------------------
       /* Numbers "Table" CTE: 1) TOP has variable parameter = DATALENGTH(@String), 2) Use ROW_NUMBER */
       [CTE_Numbers]
       AS (SELECT TOP (ISNULL(DATALENGTH(@String), 0)) [Number] = ROW_NUMBER() OVER(ORDER BY (SELECT NULL) )
           FROM [CTE_10000]),
       -------------------
       /* Returns start of the element after each delimiter */
       [CTE_Start]
       AS (SELECT [Start] = 1
           UNION ALL
           SELECT [Start] = [Number] + 1 -- This 1 is because we want to start the next word 1 AFTER the delimiter
           FROM [CTE_Numbers]
           WHERE SUBSTRING(@String, [Number], 1) NOT LIKE '[a-zA-Z0-9]'),
       -------------------
       /* Returns the length of each word by comparing against the NEXT Start */
       [CTE_Lengths]
       AS (SELECT [Start]
                  -- This is NextStart - ThisStart - 1. The "- 1" is to keep the length coming up to (not *including*) the next delimiter
                  -- For the last word, NextStart would be NULL - so we go to the end of @String instead
                , [Length] = ISNULL(LEAD([Start]) OVER (ORDER BY [Start]) - [Start] - 1
                                  , DATALENGTH(@String) - [Start] + 1)
           FROM [CTE_Start])

       /* Do the actual split */
       SELECT [ID] = ROW_NUMBER() OVER(ORDER BY [Start])
            , [Word] = SUBSTRING(@String, [Start], [Length])
       FROM [CTE_Lengths]
       WHERE [Length] > 0 -- This is to avoid empty strings created by back-to-back non-word characters
GO

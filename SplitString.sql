CREATE FUNCTION [Tools].[SplitString] (@String    VARCHAR(8000) -- DO NOT USE MAX DATA-TYPES HERE!  IT WILL KILL PERFORMANCE!
                                     , @Delimiter VARCHAR(8000))
/*
This function splits a VARCHAR string into a table of elements/items by some delimiter
The table returns ID (by the order of occurance) and String (the element)

EXAMPLE: 
SELECT * 
FROM [Tools].[SplitString] ('a list,of,items', ',')
ID | String
###########
1  | a list
2  | of
3  | items

This is based off Jeff Moden's DelimitedSplit8K function: http://www.sqlservercentral.com/articles/Tally+Table/72993/
It has been modified to:
      1) Accept a delimiter longer than 1 character
      2) Deal with delimiter of 0 length (i.e. '')
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
       /* 10000 rows max (all 1s) - this limits the number of elements to 10k (which is fine, because our datatype only accepts 8k characters) */
       [CTE_10000]
       AS (SELECT [Number] = 1
           FROM [CTE_100] [a]
                CROSS JOIN [CTE_100] [b]),
       -------------------
       /* Numbers "Table" CTE: 
          1) TOP has variable parameter = DATALENGTH(@String)
          2) Use ROW_NUMBER */
       [CTE_Numbers]
       AS (SELECT TOP (ISNULL(DATALENGTH(@String), 0)) [Number] = ROW_NUMBER() OVER(ORDER BY (SELECT NULL) )
           FROM [CTE_10000]),
       -------------------
       /* Returns start of the element after each delimiter */
       [CTE_Start]
       AS (SELECT [Start] = 1
           WHERE DATALENGTH(@Delimiter) > 0
           UNION ALL
           SELECT [Start] = [Number] + DATALENGTH(@Delimiter)
           FROM [CTE_Numbers]
           WHERE SUBSTRING(@String, [Number], DATALENGTH(@Delimiter)) = @Delimiter),
       -------------------
       /* IF @Delimiter <> '': Returns start and length (for use in substring) */
       [CTE_Length]
       AS (SELECT [Start]
                , [Length] = ISNULL(NULLIF(CHARINDEX(@Delimiter, @String, [Start]), 0) - [Start], 8000) -- ISNULL/NULLIF combo handles the length for the final element when no delimiter is found.
           FROM [CTE_Start]
           WHERE DATALENGTH(@Delimiter) > 0),
       -------------------
       /* IF @Delimiter = '': Returns start and length (for use in substring) */
       [CTE_Length2]
       AS (SELECT [Start]
                , [Length] = 1
           FROM [CTE_Start]
           WHERE DATALENGTH(@Delimiter) = 0)

       /* Do the actual split */
       SELECT [ID] = ROW_NUMBER() OVER(ORDER BY [Start])
            , [String] = SUBSTRING(@String, [Start], [Length])
       FROM [CTE_Length]
       UNION ALL
       SELECT [ID] = ROW_NUMBER() OVER(ORDER BY [Start])
            , [String] = SUBSTRING(@String, [Start], [Length])
       FROM [CTE_Length2];
GO



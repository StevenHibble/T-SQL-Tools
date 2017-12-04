CREATE FUNCTION [Tools].[ReorderString](@String    VARCHAR(8000) -- DO NOT USE MAX DATA-TYPES HERE!  IT WILL KILL PERFORMANCE!
                                      , @Delimiter VARCHAR(8000)
                                      , @Order     VARCHAR(8000))
/*
This function splits a VARCHAR string into a table of elements/items by some delimiter (using [Tools].[SplitString])
Then, the @Order is parsed as comma-separated list of INTs (or using the special value 'REVERSE')
Last, @String is re-concatenated in the order specified
The table returns a single column ReorderedString (with only 1 row)

NOTE: Most commonly, I use this to fix variable structure (e.g. 'VAR_RIGHT_LEFT_END' -> 'VAR_LEFT_RIGHT_END')
      It can also be used to drop portions of the string

EXAMPLE #1 (simple usage): 
SELECT * 
FROM [Tools].[ReorderString] ('apple,banana,grape', ',', '2,3,1')
ReorderedString
###########
banana,grape,apple

EXAMPLE #2 (using 'REVERSE'): 
SELECT * 
FROM [Tools].[ReorderString] ('how now brown cow', ' ', 'REVERSE')
ReorderedString
###########
cow brown now how

EXAMPLE #3 (dropping elements): 
SELECT * 
FROM [Tools].[ReorderString] ('how now brown cow', ' ', '1,4')
ReorderedString
###########
how cow
*/
RETURNS TABLE
WITH SCHEMABINDING
AS
  RETURN
       /* Split @String */
  WITH [CTE_Split]
       AS (SELECT [ID]
                , [String]
           FROM [Tools].[SplitString] (@String, @Delimiter) ),
       -------------------
       /* Parse @Order into list of numbers */
       [CTE_Order]
       AS (SELECT [ID]
                , [Order] = CONVERT(INT, [String])
           FROM [Tools].[SplitString] (REPLACE(@Order, ' ', ''), ',')
           WHERE @Order <> 'REVERSE'
           UNION ALL
           SELECT [ID]
                , [Order] = (SELECT MAX([ID])
                             FROM [CTE_Split]) - [ID] + 1
           FROM [CTE_Split]
           WHERE @Order = 'REVERSE'),
       -------------------
       /* Combine substrings with order, assigning a new ID to the substring */
       [CTE_Reorder]
       AS (SELECT [ss].[String]
                , [o].[ID]
           FROM [CTE_Split] [ss]
                JOIN [CTE_Order] [o]
                  ON [ss].[ID] = [o].[Order])

       /* Recombine @String in new order  */
       SELECT [ReorderedString] = STUFF( (SELECT @Delimiter+[String]
                                          FROM [CTE_Reorder]
                                          ORDER BY [ID]
                                          FOR XML PATH(''), TYPE).value ('.', 'varchar(8000)'), 1, DATALENGTH(@Delimiter), '');
GO



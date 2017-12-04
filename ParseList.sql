CREATE FUNCTION [Tools].[ParseList] (@List      VARCHAR(8000)
                                   , @Delimiter VARCHAR(8000) = ',')
/*
This function splits a VARCHAR list into a table of elements/items by some delimiter (using [Tools].[SplitString])
Then, it parses items as either Selected/Unselected (by parsing whether or not the item begins with '-')
The table returns Item (the element) and Selected (whether or not the element was preceded by '-')

NOTE: I use this mostly as a helper function for returning/not returning certain items (e.g. databases, key values)
      It is especially helpful when used with like patterns

EXAMPLE #1 (straight forward usage): 
SELECT * 
FROM [Tools].[ParseList] ('master,model,-tempdb,msdb', ',')
Item   | Selected
###########
master | 1
model  | 1
tempdb | 0
msdb   | 1

EXAMPLE #2 (using LIKE and EXISTS):
-- This returns all objects that (1) start with 'sp', but not 'spt'; or (2) contain the letters 'MS'
-- You can include 
SELECT *
FROM [master].[sys].[objects]
WHERE EXISTS (SELECT 1
              FROM [Tools].[ParseList] ('sp%,-spt%,%MS%', ',')
              WHERE [name] LIKE [Item] AND [Selected] = 1)
      AND NOT EXISTS (SELECT 1
                      FROM [Tools].[ParseList] ('sp%,-spt%,%MS%', ',')
                      WHERE [name] LIKE [Item] AND [Selected] = 0);

This is based off Ola Hallengren's code in his Maintenance Solutions: https://ola.hallengren.com/scripts/MaintenanceSolution.sql
It has been adapted to be a function for reuse
*/ 
RETURNS TABLE
WITH SCHEMABINDING
AS
  RETURN
       /* Remove spaces after the delimiter (e.g. ', ' becomes ',') */
  WITH [RemoveSpaces]
       AS (SELECT [List] = REPLACE(@List, @Delimiter+' ', @Delimiter)),
       /* Split into List table */
       [SplitList]
       AS (SELECT [Item] = [String]
           FROM [RemoveSpaces]
            CROSS APPLY [Tools].[SplitString] ([List], @Delimiter) [ss])

       /* Find which Items are Selected/Not-Selected */
       SELECT [Item] = CASE
                         WHEN [Item] LIKE '-%' THEN RIGHT([Item], LEN([Item]) - 1)
                         ELSE [Item]
                       END
            , [Selected] = CASE
                             WHEN [Item] LIKE '-%' THEN 0
                             ELSE 1
                           END
       FROM [SplitList];



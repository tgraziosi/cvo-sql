SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Select and process BO substitutions without user interaction.
-- All selection logic is defined in the sp cvo_bo_to_subst_st
-- Use the select and process routines written by CSG (Chris Tyler)
-- author - TAG - 06/15/2015

-- exec cvo_bo_substitute_automatic_sp

CREATE PROCEDURE [dbo].[cvo_bo_substitute_automatic_sp]
AS 

SET NOCOUNT ON	

DECLARE @starttime DATETIME
SELECT @starttime = GETDATE()

IF ( OBJECT_ID('tempdb.dbo.#t') IS NOT NULL )
    DROP TABLE #t;


CREATE TABLE #t
( brand VARCHAR(10)
, style VARCHAR(40)
, part_no VARCHAR(30)
, type_code varchar(10)
, order_no int
, ext int
, user_category VARCHAR(10)
, date_entered DATETIME
, location VARCHAR(10)
, open_qty INT
, sub_part_no VARCHAR(30)
, qty_to_sub INT
, qty_avl_to_sub INT
, nextpoduedate VARCHAR(12)
, id INT IDENTITY (1,1)
)

INSERT INTO #t
        ( brand ,
          style ,
          part_no ,
          type_code ,
          order_no ,
          ext ,
          user_category ,
          date_entered ,
          location ,
          open_qty ,
          sub_part_no ,
          qty_to_sub ,
          qty_avl_to_sub ,
          nextpoduedate
        )
EXEC dbo.cvo_bo_to_subst_st

-- SELECT COUNT(id) FROM #t WHERE qty_to_sub > 0

-- SELECT * FROM #t where qty_to_sub > 0

DECLARE @id INT, @order_no INT, @ext INT, @part_no VARCHAR(30), @replacement_part_no VARCHAR(30)

SELECT @id = 0
SELECT @id = min(id) FROM #t WHERE qty_to_sub > 0 AND id > @id
SELECT @order_no = order_no, @ext = ext, @part_no = part_no, @replacement_part_no = sub_part_no
	FROM #t WHERE id = @id

WHILE @id IS NOT NULL 
-- 	AND @id < 50
BEGIN
 -- SELECT @id, @order_no, @ext, @part_no, @replacement_part_no
 EXEC cvo_substitute_processing_select_sp @order_no, @order_no, @ext, @ext, NULL, NULL, null, null, null, @part_no, @replacement_part_no, 1
 EXEC dbo.cvo_substitute_processing_process_sp @@spid , 1
 SELECT @id = MIN(id) FROM #t WHERE qty_to_sub > 0 AND id > @id
 SELECT @order_no = order_no, @ext = ext, @part_no = part_no, @replacement_part_no = sub_part_no
	FROM #t WHERE id = @id
end

--SELECT * FROM [cvo_substitute_processing_log]  WHERE log_time > '06/19/2015'  AND spid = 76

-- SELECT * FROM cvo_substitute_processing_error WHERE spid = @@SPID

--WHERE spid = @@spid AND log_time >= @starttime

GO
GRANT EXECUTE ON  [dbo].[cvo_bo_substitute_automatic_sp] TO [public]
GO

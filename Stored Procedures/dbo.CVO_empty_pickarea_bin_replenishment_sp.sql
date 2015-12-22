SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0		28-FEB-2012	Created DMoon


-- Execute CVO_empty_pickarea_bin_replenishment_sp

CREATE PROCEDURE [dbo].[CVO_empty_pickarea_bin_replenishment_sp]

AS
BEGIN
	SET NOCOUNT ON


	DECLARE @tran_id		int,
			@last_tran_id	int,
			@location		varchar(10),
			@part_no		varchar(30),
			@bin_no			varchar(20),
			@next_op		varchar(20),
			@qty			decimal(20,8),
			@id				int,
			@last_id		int

	SET @last_tran_id = 0



	-- Processing Highbay moves
	CREATE TABLE #pickarea_process (
				id			int identity(1,1), 
				part_no		varchar(30),
				bin_no		varchar(20),
				qty			decimal(20,8))

	-- Deal with empty bins first
	INSERT	#pickarea_process (part_no, bin_no, qty)
	SELECT	part_no, 
			bin_no,
			0
	FROM    dbo.cvo_empty_pickarea_repl_bin_vw (NOLOCK)

-- select * from #pickarea_process


	SET @last_id = 0

	SELECT	TOP 1 @id = id,
			@part_no = part_no,
			@bin_no = bin_no
	FROM	#pickarea_process
	WHERE	id > @last_id
	ORDER BY id ASC

	WHILE @@ROWCOUNT <> 0
	BEGIN
	

		EXEC tdc_automatic_bin_replenish  '001', @part_no, @bin_no, 0, 0

		SET @last_id = @id

		SELECT	TOP 1 @id = id,
				@part_no = part_no,
				@bin_no = bin_no
		FROM	#pickarea_process
		WHERE	id > @last_id
		ORDER BY id ASC

	END


	DROP TABLE #pickarea_process


	RETURN
END


-- select * from tdc_pick_queue where trans = 'mgtb2b' and trans_type_no = 0 order by tran_id -- 1708983
GO

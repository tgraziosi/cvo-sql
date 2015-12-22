SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_print_works_order_sp] @order_no	int,
										 @order_ext	int
AS
BEGIN

	-- Directives
	SET NOCOUNT ON

	-- START v1.1
	/*
	IF NOT EXISTS (SELECT * FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv')
			INSERT INTO tdc_config ([function],mod_owner, description, active) VALUES ('mod_ebo_inv','EBO','Allow modify inventory from eBO','Y')	

	IF @@ERROR <> 0
	BEGIN
		SELECT -1
		RETURN
	END
	*/

	IF (OBJECT_ID('tempdb..#PrintData') IS NOT NULL) 
		DROP TABLE #PrintData

	IF @@ERROR <> 0
	BEGIN
		SELECT -1
		RETURN
	END

	CREATE TABLE #PrintData 
	(row_id			INT IDENTITY (1,1)	NOT NULL
	,data_field		VARCHAR(300)		NOT NULL
	,data_value		VARCHAR(300)			NULL)

	IF @@ERROR <> 0
	BEGIN
		SELECT -1
		RETURN
	END
	
	EXEC CVO_disassembled_frame_sp @order_no, @order_ext

	IF @@ERROR <> 0
	BEGIN
		SELECT -1
		RETURN
	END
	
	EXEC CVO_disassembled_inv_adjust_sp @order_no, @order_ext

	IF @@ERROR <> 0
	BEGIN
		SELECT -1
		RETURN
	END
		
	EXEC CVO_disassembled_print_inv_adjust_sp @order_no, @order_ext		

	IF @@ERROR <> 0
	BEGIN
		SELECT -1
		RETURN
	END
		
	-- START v1.1
	/*
	DELETE FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv'  

	IF @@ERROR <> 0
	BEGIN
		SELECT -1
		RETURN
	END
	*/
	-- END v1.1

	SELECT 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_print_works_order_sp] TO [public]
GO

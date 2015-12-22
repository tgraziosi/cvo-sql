SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* This SP is used to Re-seq the orders in the current consolidation set */
/*									 */
/* Return Values:							 */
/*	 Returns  errMsg 						 */
/*									 */
/* Notes:*/
/*									  */
/* 		Initial		MK		*/

CREATE PROCEDURE [dbo].[tdc_resequence_sp]
@Cons_no int 
AS

DECLARE @ord int,
	@ext int,
	@Cnt int,
	@msg varchar(80)

BEGIN


	DECLARE seq_cursor CURSOR FOR
	SELECT  order_no, order_ext 
	FROM    #temp_ship_fill  (NOLOCK)
	WHERE   consolidation_no = @Cons_no
	
	OPEN seq_cursor
	FETCH NEXT FROM seq_cursor INTO @ord, @ext 

	--'Set Cnt = 0
	SELECT @Cnt = 0 

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		/* otherwise just update the table with 0 because we don't have any avail inv */
		SELECT @Cnt = @Cnt + 1 

		UPDATE tdc_cons_ords
			SET    seq_no =  @Cnt 
		WHERE 	consolidation_no = @Cons_no 
			AND	order_no = @ord 
			AND    order_ext = @ext
			AND   order_type = 'S'

		FETCH NEXT FROM seq_cursor INTO @ord, @ext
	END

	CLOSE seq_cursor
	DEALLOCATE seq_cursor
	

END
GO
GRANT EXECUTE ON  [dbo].[tdc_resequence_sp] TO [public]
GO

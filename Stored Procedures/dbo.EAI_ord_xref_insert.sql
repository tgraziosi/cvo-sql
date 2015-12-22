SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[EAI_ord_xref_insert]
	(
	@BO_order_no		int,
	@BO_order_ext		int,
	@FO_order_no		VARCHAR(100),
	@source			VARCHAR(100) = Null
	)
AS
BEGIN
/* the procedure returns 1 if unsuccessful, 0 if successful */

	if exists (select 'X' from EAI_ord_xref (NOLOCK)
		   		where (BO_order_no = @BO_order_no and 
				BO_order_ext = @BO_order_ext) or
				FO_order_no = @FO_order_no) 
	   begin
		return 0	-- the order is already exist in EAI_ord_xref
	   end
	else
	   begin
		insert EAI_ord_xref(BO_order_no, BO_order_ext, FO_order_no, source)
		VALUES (@BO_order_no, @BO_order_ext, @FO_order_no, @source)
		
		return 0
	   end				
return 0
END
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_xref_insert] TO [public]
GO

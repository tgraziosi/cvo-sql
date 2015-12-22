SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create proc [dbo].[tdc_get_next_sscc_sp] 
as

declare @sscc int

/* Initialization */
select @sscc = -1

/* Update table */
update tdc_next_sscc_tbl
   	set @sscc = serial_no = serial_no + 1

/* If error occurred, -1 will be returned */
select @sscc = serial_no from tdc_next_sscc_tbl
RETURN @sscc
GO
GRANT EXECUTE ON  [dbo].[tdc_get_next_sscc_sp] TO [public]
GO

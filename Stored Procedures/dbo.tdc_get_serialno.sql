SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[tdc_get_serialno] as

declare @serial_no int

/* Initialization */
select @serial_no = -1

/* Update table */
update tdc_dist_next_serial_num
   	set @serial_no = serial_no = serial_no + 1

/* If error occurred, -1 will be returned */
return @serial_no



GO
GRANT EXECUTE ON  [dbo].[tdc_get_serialno] TO [public]
GO

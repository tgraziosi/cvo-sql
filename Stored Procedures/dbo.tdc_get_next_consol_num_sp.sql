SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.tdc_get_next_consol_num_sp    Script Date: 5/5/99 6:20:20 PM ******/
create proc [dbo].[tdc_get_next_consol_num_sp] 
as

declare @serial_no int

/* Initialization */
select @serial_no = -1

/* Update table */
update tdc_next_consol_num_tbl
   	set @serial_no = serial_no = serial_no + 1

/* If error occurred, -1 will be returned */
select @serial_no = serial_no from tdc_next_consol_num_tbl
RETURN @serial_no
GO
GRANT EXECUTE ON  [dbo].[tdc_get_next_consol_num_sp] TO [public]
GO

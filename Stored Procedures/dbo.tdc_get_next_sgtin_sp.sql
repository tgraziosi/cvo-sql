SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create proc [dbo].[tdc_get_next_sgtin_sp] 
@part_no varchar(30)
as

declare @sgtin int

/* Initialization */
select @sgtin = -1

/* Update table */
if not exists(select * from tdc_next_sgtin_tbl (NOLOCK) WHERE part_no = @part_no)
begin
	insert into tdc_next_sgtin_tbl(part_no, serial_no) values (@part_no, 1)
	set @sgtin = 1
end
else
begin
	update tdc_next_sgtin_tbl
	   set @sgtin = serial_no = serial_no + 1
	 where part_no = @part_no
end


/* If error occurred, -1 will be returned */
select @sgtin = serial_no from tdc_next_sgtin_tbl where part_no = @part_no
RETURN @sgtin
GO
GRANT EXECUTE ON  [dbo].[tdc_get_next_sgtin_sp] TO [public]
GO

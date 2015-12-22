SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ser_del_serial_no] @part_no varchar(30), @serial_no varchar(25), @tran_type char(1) AS
BEGIN -- begin proc

declare @c_part_no varchar(30)
declare @c_serial_no varchar(30)

select @c_part_no = @part_no
select @c_serial_no = @serial_no

--if transaction type is Inv adj then the out transaction will not delete from the control table, but it will add the part and the serial number to a holding table
-- then when or if the serial part combo come back it will check the holding table to see if the number can be reinstated.
if(@tran_type = 'I')
begin
	update serial_ctrl set issue_hold_flag = 'Y' where part_no = @c_part_no and serial_no = @c_serial_no

	return 0
END 
if(@tran_type = 'C')									-- mls 7/27/01 SCR 27301 start
begin
	update serial_ctrl set issue_hold_flag = 'S' where part_no = @c_part_no and serial_no = @c_serial_no and issue_hold_flag = 'C'

	if @@rowcount = 0
	  delete from serial_ctrl where part_no = @c_part_no and serial_no = @c_serial_no
 
	return 0 
END 											-- mls 7/27/01 SCR 27301 end
if(@tran_type = 'S')									-- mls 7/27/01 SCR 27301 start
begin
	update serial_ctrl set issue_hold_flag = 'S' where part_no = @c_part_no and serial_no = @c_serial_no 

	return 0 
END 											-- mls 7/27/01 SCR 27301 end
if @tran_type not in ('C','I','S') -- this is a normal transaction, so the serial number will be taken out of the serial control table.
begin

	Delete from serial_ctrl where part_no = @c_part_no and serial_no = @c_serial_no

	return 0

END

END -- end proc
GO
GRANT EXECUTE ON  [dbo].[ser_del_serial_no] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ser_vrf_serial_no] @c_part_no varchar(30), @c_serial_no varchar(25), @c_tran_type char(1) AS
BEGIN -- Start proc


-- This procedure checks to see if a serial number exists in the serial_ctrl table. It returns a 1 if it exists, and a 0 if it doesn't.
-- Also see comments on added code.

declare @hold_flag char(1)

select @hold_flag = isnull((select issue_hold_flag from serial_ctrl (nolock) where part_no = @c_part_no and serial_no = @c_serial_no),'!')
-- if the transaction is of type 'I' which is an inventory adjustment.
IF (@c_tran_type = 'I')
BEGIN
	-- this checks to see if the inventory adjust has been done to this particular serial number if it has, we send it back as if the serial # doesn't exist
	if( @hold_flag = 'Y')
		return 0
END 
if (@c_tran_type = 'A')
begin
	if (@hold_flag in ('Y','A'))
		return 0
end 
IF (@c_tran_type = 'B')	-- release from adhoc qc
BEGIN
	if( @hold_flag = 'A')
		return 0
END 
IF (@c_tran_type = 'C')								-- mls 7/27/01 SCR 27301 start
BEGIN
	-- this checks to see if a shipment has been done to this particular serial number if it has, we send it back as if the serial # doesn't exist
	if( @hold_flag = 'S')
		return 0
END 										-- mls 7/27/01 SCR 27301 end

if (@c_tran_type = 'R')								-- mls 4/23/02 SCR 28797 start
BEGIN
  if @hold_flag = 'Q'
    return 0
END										-- mls 4/23/02 SCR 28797 end

if( @hold_flag = 'S')
	return -1

if (@hold_flag = 'Y')
	return -2

if @hold_flag != '!'
	return 1

return 0

END-- end proc

GO
GRANT EXECUTE ON  [dbo].[ser_vrf_serial_no] TO [public]
GO

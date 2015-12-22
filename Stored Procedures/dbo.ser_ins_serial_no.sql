SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ser_ins_serial_no] @c_part_no varchar(30), @c_serial_no varchar(30), @c_tran_type char(1) AS
BEGIN --Start proc

-- This procedure is inserting a serial number into the serial_ctrl table, If the serial number already exists it throws and error.
-- unless the transaction is of a type = 'I', inventory adjustment. The reason for this, without this change, once a part is scrapped there is no 
-- way to unscrap it. This is fine is some situations, but not in all. If the user makes a mistake, then they are out of luck. 
-- Also without this check then transfers cannot work. Because the tran table is so closely tied to the stock table, to get a 'paper' trail of what and where 
-- part goes you must decrement and then increment stock to show what happened. Unless this holding table is used, that cannot happen. 

declare @c_part_no_holder varchar(30)
declare @c_serial_no_holder varchar(30)
declare @error varchar(100)
declare @hold_flag char(1)

-- Get the part and serial numbers
select @c_part_no_holder = @c_part_no
select @c_serial_no_holder = @c_serial_no

--Inventory adj
if (@c_tran_type = 'I')
BEGIN
	-- if is in the holding table.
	--if (exists(select * from issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
	if (exists(select * from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'Y'))
	BEGIN
		---delete it is no longer on hold or scrap status.
		--delete issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder
		update serial_ctrl set issue_hold_flag = 'N' where  part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'Y'
	END
	ELSE -- not in the holding table
	BEGIN
		if (exists(select 1 from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
		begin
		  Rollback Tran
		  select @error = 'Error assigning serial number to control table for inv adj.  Serial already exists.'
		  RaisError 90000 @error
	 	  return
		end											-- mls 4/20/01 SCR 26762 end
		-- Insert them...
		insert serial_ctrl (part_no , serial_no) (select @c_part_no_holder , @c_serial_no_holder)
		-- If the part and serial number combination already exists...
		if @@ERROR <> 0 begin
			 Rollback Tran
			 select @error = 'Error assigning serial number to control table.  Serial already exists.'
 			 RaisError 90000 @error
 	 		return
		end
	END
END
-- enter adhoc qc
if (@c_tran_type = 'A')
BEGIN
	-- if is in the holding table.
	--if (exists(select * from issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
	if (exists(select 1 from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'Y'))
	BEGIN
		---delete it is no longer on hold or scrap status.
		--delete issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder
		update serial_ctrl set issue_hold_flag = 'A' where  part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'Y'
	END
	ELSE -- not in the holding table
	BEGIN
		select @hold_flag = isnull((select issue_hold_flag from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder),'')
		if @hold_flag not in ('','A')
		begin
		  Rollback Tran
		  select @error = 'Error assigning serial number to control table for adhoc qc.  Serial already exists.'
		  RaisError 90000 @error
	 	  return
		end			
		if @hold_flag = ''
		begin								-- mls 4/20/01 SCR 26762 end
		-- Insert them...
		insert serial_ctrl (part_no , serial_no, issue_hold_flag) 
        	select @c_part_no_holder , @c_serial_no_holder, 'A'
		-- If the part and serial number combination already exists...
		if @@ERROR <> 0 begin
			 Rollback Tran
			 select @error = 'Error assigning serial number to control table.  Serial already exists.'
 			 RaisError 90000 @error
 	 		return
		end
		end
	END
END
-- releasing adhoc qc
if (@c_tran_type = 'B')
BEGIN
	-- if is in the holding table.
	--if (exists(select * from issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
	if (exists(select 1 from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'A'))
	BEGIN
		---delete it is no longer on hold or scrap status.
		--delete issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder
		update serial_ctrl set issue_hold_flag = 'N' where  part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'A'
	END
	ELSE -- not in the holding table
	BEGIN
		if (exists(select 1 from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
		begin
		  Rollback Tran
		  select @error = 'Error assigning serial number to control table for released adhoc qc.  Serial already exists.'
		  RaisError 90000 @error
	 	  return
		end											-- mls 4/20/01 SCR 26762 end
		-- Insert them...
		insert serial_ctrl (part_no , serial_no, issue_hold_flag) 
        	select @c_part_no_holder , @c_serial_no_holder, 'N'
		-- If the part and serial number combination already exists...
		if @@ERROR <> 0 begin
			 Rollback Tran
			 select @error = 'Error assigning serial number to control table.  Serial already exists.'
 			 RaisError 90000 @error
 	 		return
		end
	END
END
if (@c_tran_type = 'C')								-- mls 7/27/01 SCR 27301 start		
BEGIN
	-- if is in the holding table.
	--if (exists(select * from issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
	if (exists(select * from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'S'))
	BEGIN
		---delete it is no longer on hold or scrap status.
		--delete issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder
		update serial_ctrl set issue_hold_flag = 'C' where  part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'S'
	END
	ELSE -- not in the holding table
	BEGIN
		if (exists(select 1 from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
		begin
		  Rollback Tran
		  select @error = 'Error assigning serial number to control table for credit return.  Serial already exists.'
		  RaisError 90000 @error
	 	  return
		end											-- mls 4/20/01 SCR 26762 end
		-- Insert them...
		insert serial_ctrl (part_no , serial_no) (select @c_part_no_holder , @c_serial_no_holder)
		-- If the part and serial number combination already exists...
		if @@ERROR <> 0 begin
			 Rollback Tran
			 select @error = 'Error assigning serial number to control table.  Serial already exists.'
 			 RaisError 90000 @error
 	 		return
		end
	END
END	
if @c_tran_type = 'R'							-- mls 4/23/02 SCR 28797 start
begin
	-- if is in the holding table.
	--if (exists(select * from issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
	if (exists(select 1 from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'Q'))
	BEGIN
		---delete it is no longer on hold or scrap status.
		--delete issue_serial_holder where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder
		update serial_ctrl set issue_hold_flag = 'N' where  part_no = @c_part_no_holder and serial_no = @c_serial_no_holder and issue_hold_flag = 'Q'
	END
	ELSE -- not in the holding table
	BEGIN
		if (exists(select 1 from serial_ctrl where part_no = @c_part_no_holder and serial_no = @c_serial_no_holder))
		begin
		  Rollback Tran
		  select @error = 'Error assigning serial number to control table for credit return.  Serial already exists.'
		  RaisError 90000 @error
	 	  return
		end											-- mls 4/20/01 SCR 26762 end
		-- Insert them...
		insert serial_ctrl (part_no , serial_no) (select @c_part_no_holder , @c_serial_no_holder)
		-- If the part and serial number combination already exists...
		if @@ERROR <> 0 begin
			 Rollback Tran
			 select @error = 'Error assigning serial number to control table.  Serial already exists.'
 			 RaisError 90000 @error
 	 		return
		end
	END
end									-- mls 4/23/02 SCR 28797 end

if @c_tran_type not in ('A','B','C','I','R')  --c_tran_type <> 'I','C' not an invetory adj or credit return -- mls 7/27/01 SCR 27301
BEGIN
	if exists (select 1 from serial_ctrl where part_no = @c_part_no_holder 			-- mls 4/20/01 SCR 26762 start
          and serial_no = @c_serial_no_holder)
	begin
		 Rollback Tran
		 select @error = 'Error assigning serial number to control table.  Serial already exists.'
	 	 RaisError 90000 @error
	 	 return
	end											-- mls 4/20/01 SCR 26762 end

	-- Insert them...
	insert serial_ctrl (part_no , serial_no, issue_hold_flag) 
        select @c_part_no_holder , @c_serial_no_holder,
          case when @c_tran_type = 'Q' then 'Q' else 'N' end				-- mls 4/23/02 SCR 28797
	-- If the part and serial number combination already exists...
	if @@ERROR <> 0 begin
		 Rollback Tran
		 select @error = 'Error assigning serial number to control table.  Serial already exists.'
	 	 RaisError 90000 @error
	 	 return
	end
END

END -- end proc
GO
GRANT EXECUTE ON  [dbo].[ser_ins_serial_no] TO [public]
GO

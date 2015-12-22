CREATE TABLE [dbo].[part_price]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_key] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[price_a] [decimal] (20, 8) NULL,
[price_b] [decimal] (20, 8) NULL,
[price_c] [decimal] (20, 8) NULL,
[price_d] [decimal] (20, 8) NULL,
[price_e] [decimal] (20, 8) NULL,
[price_f] [decimal] (20, 8) NULL,
[qty_a] [decimal] (20, 8) NULL,
[qty_b] [decimal] (20, 8) NULL,
[qty_c] [decimal] (20, 8) NULL,
[qty_d] [decimal] (20, 8) NULL,
[qty_e] [decimal] (20, 8) NULL,
[qty_f] [decimal] (20, 8) NULL,
[promo_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_rate] [decimal] (20, 8) NULL,
[promo_date_expires] [datetime] NULL,
[promo_date_entered] [datetime] NULL,
[promo_start_date] [datetime] NULL,
[last_system_upd_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_part_price_insupd] ON [dbo].[part_price]   FOR INSERT, UPDATE  AS 
BEGIN
	DECLARE @item_id varchar(30), @curr_key varchar(10), @data varchar(50)
	Declare @last_item_id varchar(30), @last_curr_key varchar(10)	-- rev 2
	Declare @send_document_flag char(1)  -- rev 4
    DECLARE @Sender		varchar(32) 
    DECLARE @nResult      	int




	if exists( SELECT * FROM config WHERE flag = 'EAI' and value_str = 'Y') begin	-- EAI is enabled
		select @last_item_id = ''
		select @last_curr_key = ''
		while 1 = 1 begin 		-- (loop through until the break)
		
			Set ROWCOUNT 1
			select @send_document_flag = 'N'

			If (not (Exists( select 'X' from deleted))) begin
				--Case of Update or insert
				select @item_id = part_no, @curr_key = curr_key 
				from inserted
				where convert(char(30), part_no) + convert(char(10), curr_key) >
				      convert(char(30), @last_item_id) + convert(char(10), @last_curr_key)
				order by part_no, curr_key
			end
			else begin
				-- Case of Delete
				select @item_id = part_no, @curr_key = curr_key 
				from deleted
				where convert(char(30), part_no) + convert(char(10), curr_key) >
				      convert(char(30), @last_item_id) + convert(char(10), @last_curr_key)
				order by part_no, curr_key
			end

			If @@Rowcount <= 0 
			begin 
			      set rowcount 0
			      BREAK	-- this will exit the loop!
			end
			Set ROWCOUNT 0

			if (exists(select @item_id) and exists (select @curr_key)) begin
			   if ((exists (select distinct 'X' from inserted i, deleted d
				where	((i.price_a <> d.price_a OR 
					  i.price_b <> d.price_b OR
					  i.price_c <> d.price_c OR
					  i.price_d <> d.price_d OR
					  i.price_e <> d.price_e OR
                      i.price_f <> d.price_f OR
					  i.qty_a   <> d.qty_a   OR
					  i.qty_b   <> d.qty_b   OR
					  i.qty_c   <> d.qty_c   OR
					  i.qty_d   <> d.qty_d   OR
					  i.qty_e   <> d.qty_e   OR
                      i.qty_f   <> d.qty_f  
					 )
				-- don't worry about custom kits or resources
				and (exists (select 'X' from inv_master (NOLOCK) 
				where part_no = @item_id and status not in ('R'))) )))
				OR (not exists(select 'X' from deleted) and 
				-- don't worry about custom kits or resources
				(exists (select 'X' from inv_master (NOLOCK) 
				where part_no = @item_id and status not in ('R'))) ))
			   begin
				select @send_document_flag = 'Y'
			   end else begin
				If ( ( 	Update(price_a) or 
					Update(price_b) or 
					Update(price_c) or 
					Update(price_d) or 
					Update(price_e) or 
					Update(qty_a  ) or 
					Update(qty_b  ) or 
					Update(qty_c  ) or 
					Update(qty_d  ) or 
					Update(qty_e  ) or
                    Update(qty_f  )
					) 
					and (exists(select 'X' from inv_master (HOLDLOCK) 
					where part_no = @item_id and status not in ('R'))))
				begin
				   select @send_document_flag = 'Y'
				end
			   end
		
			   if @send_document_flag = 'Y' 
			   begin

				 select @Sender = ddid from smcomp_vw

				-- inv_list has been changed or inserted, send data to Front Office
				 select @data = @curr_key + '|' + @item_id + '|0'	--not a serv agrmt

				 if ( @last_item_id != @item_id ) --not igual to
				 begin 
				    IF not exists (SELECT 1 from EAI_process (NOLOCK)  
						    WHERE  vb_script = 'PartPrice'
						    and data =  @data 
						    and source_platform =  'BO' and action = 0 ) 
				    BEGIN           

				       exec @nResult = EAI_Send_sp 'PartPrice', @data , 'BO', 1, @Sender

				    END
				 end
				 else 
				   exec EAI_process_insert 'PartPrice', @data, 'BO'

			   end
		   	end
			
			select @last_item_id = @item_id
			select @last_curr_key = @curr_key

		end	-- end while loop
	end	-- end EAI enabled
END	-- end trigger
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700delpprice] ON [dbo].[part_price] FOR DELETE AS 
BEGIN

DECLARE @d_part_no varchar(30), @d_curr_key varchar(8), @d_price_a decimal(20,8),
@d_price_b decimal(20,8), @d_price_c decimal(20,8), @d_price_d decimal(20,8),
@d_price_e decimal(20,8), @d_price_f decimal(20,8), @d_qty_a decimal(20,8),
@d_qty_b decimal(20,8), @d_qty_c decimal(20,8), @d_qty_d decimal(20,8), @d_qty_e decimal(20,8),
@d_qty_f decimal(20,8), @d_promo_type char(1), @d_promo_rate decimal(20,8),
@d_promo_date_expires datetime, @d_promo_date_entered datetime, @d_promo_start_date datetime,
@d_last_system_upd_date datetime

declare @inv_price_id int, @catalog_id int, @p_level int, @p_qty decimal(20,8), @p_price decimal(20,8),
  @rc int, @msg varchar(255)

DECLARE t700delpart_cursor CURSOR LOCAL STATIC FOR
SELECT d.part_no, d.curr_key, d.price_a, d.price_b, d.price_c, d.price_d, d.price_e, d.price_f,
d.qty_a, d.qty_b, d.qty_c, d.qty_d, d.qty_e, d.qty_f, d.promo_type, d.promo_rate,
d.promo_date_expires, d.promo_date_entered, d.promo_start_date, d.last_system_upd_date
from deleted d

OPEN t700delpart_cursor

if @@cursor_rows = 0
begin
CLOSE t700delpart_cursor
DEALLOCATE t700delpart_cursor
return
end

FETCH NEXT FROM t700delpart_cursor into
@d_part_no, @d_curr_key, @d_price_a, @d_price_b, @d_price_c, @d_price_d, @d_price_e, @d_price_f,
@d_qty_a, @d_qty_b, @d_qty_c, @d_qty_d, @d_qty_e, @d_qty_f, @d_promo_type, @d_promo_rate,
@d_promo_date_expires, @d_promo_date_entered, @d_promo_start_date, @d_last_system_upd_date

While @@FETCH_STATUS = 0
begin
  select @inv_price_id = -1, @catalog_id = -1
  select @p_level = -1
 
  if isnull(@d_curr_key,'') <> ''
  begin
    exec @rc = adm_upd_inv_price @d_part_no, 0, '', @d_promo_type, @d_promo_rate, @d_promo_start_date,
    @d_promo_date_expires, @p_level, @p_qty, @p_price, @catalog_id OUT, @inv_price_id OUT, @d_curr_key, 1,
    @d_promo_date_entered, @msg OUT, 1 
 
    if @rc < 1 
    begin
      Rollback tran
      exec adm_raiserror 89100, @msg
    end
  end
    
FETCH NEXT FROM t700delpart_cursor into
@d_part_no, @d_curr_key, @d_price_a, @d_price_b, @d_price_c, @d_price_d, @d_price_e, @d_price_f,
@d_qty_a, @d_qty_b, @d_qty_c, @d_qty_d, @d_qty_e, @d_qty_f, @d_promo_type, @d_promo_rate,
@d_promo_date_expires, @d_promo_date_entered, @d_promo_start_date, @d_last_system_upd_date
end -- while

CLOSE t700delpart_cursor
DEALLOCATE t700delpart_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700inspprice] ON [dbo].[part_price] FOR INSERT AS 
BEGIN

DECLARE @i_part_no varchar(30), @i_curr_key varchar(8), @i_price_a decimal(20,8),
@i_price_b decimal(20,8), @i_price_c decimal(20,8), @i_price_d decimal(20,8),
@i_price_e decimal(20,8), @i_price_f decimal(20,8), @i_qty_a decimal(20,8),
@i_qty_b decimal(20,8), @i_qty_c decimal(20,8), @i_qty_d decimal(20,8), @i_qty_e decimal(20,8),
@i_qty_f decimal(20,8), @i_promo_type char(1), @i_promo_rate decimal(20,8),
@i_promo_date_expires datetime, @i_promo_date_entered datetime, @i_promo_start_date datetime,
@i_last_system_upd_date datetime

declare @inv_price_id int, @catalog_id int, @p_level int, @p_qty decimal(20,8), @p_price decimal(20,8),
  @rc int, @msg varchar(255)

DECLARE t700inspart_cursor CURSOR LOCAL STATIC FOR
SELECT i.part_no, i.curr_key, i.price_a, i.price_b, i.price_c, i.price_d, i.price_e, i.price_f,
i.qty_a, i.qty_b, i.qty_c, i.qty_d, i.qty_e, i.qty_f, i.promo_type, i.promo_rate,
i.promo_date_expires, i.promo_date_entered, i.promo_start_date, i.last_system_upd_date
from inserted i

OPEN t700inspart_cursor

if @@cursor_rows = 0
begin
CLOSE t700inspart_cursor
DEALLOCATE t700inspart_cursor
return
end

FETCH NEXT FROM t700inspart_cursor into
@i_part_no, @i_curr_key, @i_price_a, @i_price_b, @i_price_c, @i_price_d, @i_price_e, @i_price_f,
@i_qty_a, @i_qty_b, @i_qty_c, @i_qty_d, @i_qty_e, @i_qty_f, @i_promo_type, @i_promo_rate,
@i_promo_date_expires, @i_promo_date_entered, @i_promo_start_date, @i_last_system_upd_date

While @@FETCH_STATUS = 0
begin
  if not update(last_system_upd_date)
  begin
    select @inv_price_id = -1, @catalog_id = -1
    select @p_level = 1
    while @p_level < 7
    begin
	    select @p_qty = 
        case @p_level
        when 1 then @i_qty_a
        when 2 then @i_qty_b
        when 3 then @i_qty_c
        when 4 then @i_qty_d
        when 5 then @i_qty_e
        when 6 then @i_qty_f
	      end  
	    select @p_price = 
        case @p_level
        when 1 then @i_price_a
        when 2 then @i_price_b
        when 3 then @i_price_c
        when 4 then @i_price_d
        when 5 then @i_price_e
        when 6 then @i_price_f
	      end  
 
      exec @rc = adm_upd_inv_price @i_part_no, 0, '', @i_promo_type, @i_promo_rate, @i_promo_start_date,
      @i_promo_date_expires, @p_level, @p_qty, @p_price, @catalog_id OUT, @inv_price_id OUT, @i_curr_key, 1,
      @i_promo_date_entered, @msg OUT, 1 
 
      if @rc < 1 
      begin
        Rollback tran
        exec adm_raiserror 89100, @msg
      end
      
      select @p_level = @p_level + 1
    end
  end



FETCH NEXT FROM t700inspart_cursor into
@i_part_no, @i_curr_key, @i_price_a, @i_price_b, @i_price_c, @i_price_d, @i_price_e, @i_price_f,
@i_qty_a, @i_qty_b, @i_qty_c, @i_qty_d, @i_qty_e, @i_qty_f, @i_promo_type, @i_promo_rate,
@i_promo_date_expires, @i_promo_date_entered, @i_promo_start_date, @i_last_system_upd_date
end -- while

CLOSE t700inspart_cursor
DEALLOCATE t700inspart_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updpprice] ON [dbo].[part_price] FOR UPDATE AS 
BEGIN

DECLARE @i_part_no varchar(30), @i_curr_key varchar(8), @i_price_a decimal(20,8),
@i_price_b decimal(20,8), @i_price_c decimal(20,8), @i_price_d decimal(20,8),
@i_price_e decimal(20,8), @i_price_f decimal(20,8), @i_qty_a decimal(20,8),
@i_qty_b decimal(20,8), @i_qty_c decimal(20,8), @i_qty_d decimal(20,8), @i_qty_e decimal(20,8),
@i_qty_f decimal(20,8), @i_promo_type char(1), @i_promo_rate decimal(20,8),
@i_promo_date_expires datetime, @i_promo_date_entered datetime, @i_promo_start_date datetime,
@i_last_system_upd_date datetime,
@d_part_no varchar(30), @d_curr_key varchar(8), @d_price_a decimal(20,8),
@d_price_b decimal(20,8), @d_price_c decimal(20,8), @d_price_d decimal(20,8),
@d_price_e decimal(20,8), @d_price_f decimal(20,8), @d_qty_a decimal(20,8),
@d_qty_b decimal(20,8), @d_qty_c decimal(20,8), @d_qty_d decimal(20,8), @d_qty_e decimal(20,8),
@d_qty_f decimal(20,8), @d_promo_type char(1), @d_promo_rate decimal(20,8),
@d_promo_date_expires datetime, @d_promo_date_entered datetime, @d_promo_start_date datetime,
@d_last_system_upd_date datetime

declare @p_level int, @catalog_id int, @inv_price_id int,
  @p_qty decimal(20,8), @p_price decimal(20,8), @msg varchar(255), @rc int

DECLARE t700updpart_cursor CURSOR LOCAL STATIC FOR
SELECT i.part_no, i.curr_key, i.price_a, i.price_b, i.price_c, i.price_d, i.price_e, i.price_f,
i.qty_a, i.qty_b, i.qty_c, i.qty_d, i.qty_e, i.qty_f, i.promo_type, i.promo_rate,
i.promo_date_expires, i.promo_date_entered, i.promo_start_date, i.last_system_upd_date,
d.part_no, d.curr_key, d.price_a, d.price_b, d.price_c, d.price_d, d.price_e, d.price_f,
d.qty_a, d.qty_b, d.qty_c, d.qty_d, d.qty_e, d.qty_f, d.promo_type, d.promo_rate,
d.promo_date_expires, d.promo_date_entered, d.promo_start_date, d.last_system_upd_date
from inserted i, deleted d
where i.part_no = d.part_no and i.curr_key = d.curr_key

OPEN t700updpart_cursor

if @@cursor_rows = 0
begin
CLOSE t700updpart_cursor
DEALLOCATE t700updpart_cursor
return
end

FETCH NEXT FROM t700updpart_cursor into
@i_part_no, @i_curr_key, @i_price_a, @i_price_b, @i_price_c, @i_price_d, @i_price_e, @i_price_f,
@i_qty_a, @i_qty_b, @i_qty_c, @i_qty_d, @i_qty_e, @i_qty_f, @i_promo_type, @i_promo_rate,
@i_promo_date_expires, @i_promo_date_entered, @i_promo_start_date, @i_last_system_upd_date,
@d_part_no, @d_curr_key, @d_price_a, @d_price_b, @d_price_c, @d_price_d, @d_price_e, @d_price_f,
@d_qty_a, @d_qty_b, @d_qty_c, @d_qty_d, @d_qty_e, @d_qty_f, @d_promo_type, @d_promo_rate,
@d_promo_date_expires, @d_promo_date_entered, @d_promo_start_date, @d_last_system_upd_date

While @@FETCH_STATUS = 0
begin
  if not update (last_system_upd_date)
  begin
    select @inv_price_id = -1, @catalog_id = -1
    select @p_level = 1
    while @p_level < 7
    begin
	    select @p_qty = 
        case @p_level
        when 1 then @i_qty_a
        when 2 then @i_qty_b
        when 3 then @i_qty_c
        when 4 then @i_qty_d
        when 5 then @i_qty_e
        when 6 then @i_qty_f
	      end  
	    select @p_price = 
        case @p_level
        when 1 then @i_price_a
        when 2 then @i_price_b
        when 3 then @i_price_c
        when 4 then @i_price_d
        when 5 then @i_price_e
        when 6 then @i_price_f
	      end  
 
      exec @rc = adm_upd_inv_price @i_part_no, 0, '', @i_promo_type, @i_promo_rate, @i_promo_start_date,
      @i_promo_date_expires, @p_level, @p_qty, @p_price, @catalog_id OUT, @inv_price_id OUT, @i_curr_key, 1,
      @i_promo_date_entered, @msg OUT, 1 
 
      if @rc < 1 
      begin
        Rollback tran
        exec adm_raiserror 89100, @msg
      end
      
      select @p_level = @p_level + 1
    end
  end

FETCH NEXT FROM t700updpart_cursor into
@i_part_no, @i_curr_key, @i_price_a, @i_price_b, @i_price_c, @i_price_d, @i_price_e, @i_price_f,
@i_qty_a, @i_qty_b, @i_qty_c, @i_qty_d, @i_qty_e, @i_qty_f, @i_promo_type, @i_promo_rate,
@i_promo_date_expires, @i_promo_date_entered, @i_promo_start_date, @i_last_system_upd_date,
@d_part_no, @d_curr_key, @d_price_a, @d_price_b, @d_price_c, @d_price_d, @d_price_e, @d_price_f,
@d_qty_a, @d_qty_b, @d_qty_c, @d_qty_d, @d_qty_e, @d_qty_f, @d_promo_type, @d_promo_rate,
@d_promo_date_expires, @d_promo_date_entered, @d_promo_start_date, @d_last_system_upd_date
end -- while

CLOSE t700updpart_cursor
DEALLOCATE t700updpart_cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [pk_part_price] ON [dbo].[part_price] ([part_no], [curr_key]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[part_price] ADD CONSTRAINT [part_price_inv_master_fk1] FOREIGN KEY ([part_no]) REFERENCES [dbo].[inv_master] ([part_no])
GO
GRANT REFERENCES ON  [dbo].[part_price] TO [public]
GO
GRANT SELECT ON  [dbo].[part_price] TO [public]
GO
GRANT INSERT ON  [dbo].[part_price] TO [public]
GO
GRANT DELETE ON  [dbo].[part_price] TO [public]
GO
GRANT UPDATE ON  [dbo].[part_price] TO [public]
GO

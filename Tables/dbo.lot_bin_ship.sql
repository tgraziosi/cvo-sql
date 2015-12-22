CREATE TABLE [dbo].[lot_bin_ship]
(
[timestamp] [timestamp] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[date_tran] [datetime] NOT NULL,
[date_expires] [datetime] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[direction] [smallint] NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom_qty] [decimal] (20, 8) NOT NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[line_no] [int] NOT NULL,
[who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__lot_bin_s__qc_fl__17645C94] DEFAULT ('N'),
[row_id] [int] NOT NULL IDENTITY(1, 1),
[kit_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__lot_bin_s__kit_f__185880CD] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t500dellbship] ON [dbo].[lot_bin_ship]   FOR DELETE AS 
BEGIN

DECLARE @d_location varchar(10), @d_part_no varchar(30), @d_bin_no varchar(12),
@d_lot_ser varchar(25), @d_tran_code char(1), @d_tran_no int, @d_tran_ext int,
@d_date_tran datetime, @d_date_expires datetime, @d_qty decimal(20,8), @d_direction smallint,
@d_cost decimal(20,8), @d_uom char(2), @d_uom_qty decimal(20,8), @d_conv_factor decimal(20,8),
@d_line_no int, @d_who varchar(20), @d_qc_flag char(1), @d_row_id int, @d_kit_flag char(1)

declare @disable_ind int, @l_status char(1)

DECLARE t700DELlot__cursor CURSOR LOCAL STATIC FOR
SELECT d.location, d.part_no, d.bin_no, d.lot_ser, d.tran_code, d.tran_no, d.tran_ext,
d.date_tran, d.date_expires, d.qty, d.direction, d.cost, d.uom, d.uom_qty, d.conv_factor,
d.line_no, d.who, d.qc_flag, d.row_id, d.kit_flag
from deleted d

OPEN t700DELlot__cursor

if @@cursor_rows = 0
begin
CLOSE t700DELlot__cursor
DEALLOCATE t700DELlot__cursor
return
end

select @disable_ind = isnull((select 1 from config (nolock) where flag='TRIG_LBS' and value_str = 'DISABLE' ),0)

FETCH NEXT FROM t700DELlot__cursor into
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @d_row_id, @d_kit_flag

While @@FETCH_STATUS = 0
begin
  if isnull(@d_kit_flag,'N') = 'N'
  begin
    select @l_status = isnull((select status
    from ord_list l where l.order_no = @d_tran_no and l.order_ext = @d_tran_ext
      and l.line_no = @d_line_no and l.part_no = @d_part_no and l.location = @d_location),'')

    if @l_status >= 'S' and @l_status < 'V' and @disable_ind = 0
    begin
      rollback tran
      exec adm_raiserror 83231 ,'Error Deleting lot_bin_ship record.  Order line is already shipped/posted'
      return
    end
  end
  else
  begin
    select @l_status = isnull((select status
    from ord_list_kit l where l.order_no = @d_tran_no and l.order_ext = @d_tran_ext
      and l.line_no = @d_line_no and l.part_no = @d_part_no and l.location = @d_location),'')

    if @l_status >= 'S' and @l_status < 'V' and @disable_ind = 0
    begin
      rollback tran
      exec adm_raiserror 83231 ,'Error Deleting lot_bin_ship record.  Order kit line is already shipped/posted'
      return
    end
  end

  if @d_qc_flag != 'Y' and @d_qty != 0 and @d_direction < 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'S', @d_tran_no, @d_tran_ext,
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1),
	@d_conv_factor, @d_line_no, @d_who

  end

  if @d_qc_flag != 'Y' and @d_qty != 0 and @d_direction > 0 and @d_tran_code in ('S','T')
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 	
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'C', @d_tran_no, @d_tran_ext,		
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1),
	@d_conv_factor, @d_line_no, @d_who 
  end

  if @d_qc_flag = 'Y'						-- mls 3/29/02 SCR 28598 start
  begin
    rollback tran
    exec adm_raiserror 78100 ,'You Can Not Change or Delete a lot that is on QC hold!' 
    return
  end								-- mls 3/29/02 SCR 28598 end


FETCH NEXT FROM t700DELlot__cursor into
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @d_row_id, @d_kit_flag
end -- while

CLOSE t700DELlot__cursor
DEALLOCATE t700DELlot__cursor

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 22/04/2015 - Performance Changes  
  
CREATE TRIGGER [dbo].[t700inslbship] ON [dbo].[lot_bin_ship]   
FOR INSERT  
AS   
BEGIN  
  
	DECLARE @i_location varchar(10), @i_part_no varchar(30), @i_bin_no varchar(12),  
			@i_lot_ser varchar(25), @i_tran_code char(1), @i_tran_no int, @i_tran_ext int,  
			@i_date_tran datetime, @i_date_expires datetime, @i_qty decimal(20,8), @i_direction smallint,  
			@i_cost decimal(20,8), @i_uom char(2), @i_uom_qty decimal(20,8), @i_conv_factor decimal(20,8),  
			@i_line_no int, @i_who varchar(20), @i_qc_flag char(1), @i_row_id int, @i_kit_flag char(1)  
  
	DECLARE  @vend varchar(10), @rcode varchar(10), @l_status char(1), @disable_ind int  

	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int
	
	CREATE TABLE #t700inslot (
		row_id			int IDENTITY(1,1),
		i_location		varchar(10) NULL,
		i_part_no		varchar(30) NULL,
		i_bin_no		varchar(12) NULL,
		i_lot_ser		varchar(25) NULL,
		i_tran_code		char(1) NULL,
		i_tran_no		int NULL,
		i_tran_ext		int NULL,
		i_date_tran		datetime NULL,
		i_date_expires	datetime NULL,
		i_qty			decimal(20,8) NULL,
		i_direction		smallint NULL,
		i_cost			decimal(20,8) NULL,
		i_uom			varchar(2) NULL,
		i_uom_qty		decimal(20,8) NULL,
		i_conv_factor	decimal(20,8) NULL,
		i_line_no		int NULL,
		i_who			varchar(50) NULL,
		i_qc_flag		char(1) NULL,
		i_row_id		int,
		i_kit_flag		char(1) NULL)
  
	-- v1.0 DECLARE t700inslot__cursor CURSOR LOCAL STATIC FOR  
	INSERT	#t700inslot (i_location, i_part_no, i_bin_no, i_lot_ser, i_tran_code, i_tran_no, i_tran_ext, i_date_tran, i_date_expires, 
					i_qty, i_direction, i_cost, i_uom, i_uom_qty, i_conv_factor, i_line_no, i_who, i_qc_flag, i_row_id, i_kit_flag)
	SELECT	i.location, i.part_no, i.bin_no, i.lot_ser, i.tran_code, i.tran_no, i.tran_ext,  
			i.date_tran, i.date_expires, i.qty, i.direction, i.cost, i.uom, i.uom_qty, i.conv_factor,  
			i.line_no, i.who, i.qc_flag, i.row_id, i.kit_flag  
	FROM	inserted i  
  
	-- v1.0 OPEN t700inslot__cursor  
  
	-- v1.0 if @@cursor_rows = 0  
	IF (@@ROWCOUNT = 0)
	BEGIN  
		-- v1.0 CLOSE t700inslot__cursor  
		-- v1.0 DEALLOCATE t700inslot__cursor  
		RETURN  
	END  
  
	SELECT @disable_ind = ISNULL((SELECT 1 FROM config (NOLOCK) WHERE flag = 'TRIG_LBS' AND value_str = 'DISABLE' ),0)  
  
	-- v1.0
	/*
	FETCH NEXT FROM t700inslot__cursor into  
	@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,  
	@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,  
	@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @i_row_id, @i_kit_flag  
	*/

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@i_location = i_location, 
			@i_part_no = i_part_no, 
			@i_bin_no = i_bin_no, 
			@i_lot_ser = i_lot_ser, 
			@i_tran_code = i_tran_code, 
			@i_tran_no = i_tran_no, 
			@i_tran_ext = i_tran_ext, 
			@i_date_tran = i_date_tran, 
			@i_date_expires = i_date_expires, 
			@i_qty = i_qty, 
			@i_direction = i_direction, 
			@i_cost = i_cost, 
			@i_uom = i_uom, 
			@i_uom_qty = i_uom_qty, 
			@i_conv_factor = i_conv_factor, 
			@i_line_no = i_line_no, 
			@i_who = i_who, 
			@i_qc_flag = i_qc_flag, 
			@i_row_id = i_row_id, 
			@i_kit_flag = i_kit_flag
	FROM	#t700inslot
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
	
	-- v1.0 While @@FETCH_STATUS = 0  
	WHILE (@@ROWCOUNT <> 0)
	BEGIN  
		IF ISNULL(@i_kit_flag,'N') = 'N'  
		BEGIN  
			SELECT @l_status = ISNULL((SELECT status FROM ord_list l (NOLOCK) WHERE l.order_no = @i_tran_no AND l.order_ext = @i_tran_ext  
								AND l.line_no = @i_line_no AND l.part_no = @i_part_no AND l.location = @i_location),'')  
  
			IF @l_status = ''  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 83231 ,'Error Inserting lot_bin_ship record.  Order line for part does not exist'  
				RETURN  
			END  
    
			IF @l_status >= 'S' AND @disable_ind = 0  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 83231 ,'Error Inserting lot_bin_ship record.  Order line is already shipped/posted'  
				RETURN  
			END  
		END  
		ELSE  
		BEGIN  
			SELECT @l_status = ISNULL((SELECT status FROM ord_list_kit l (NOLOCK) WHERE l.order_no = @i_tran_no AND l.order_ext = @i_tran_ext  
								AND l.line_no = @i_line_no AND l.part_no = @i_part_no AND l.location = @i_location),'')  
  
			IF @l_status = ''  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 83231, 'Error Inserting lot_bin_ship record.  Order kit line for part does not exist'  
				RETURN  
			END  
    
			IF @l_status >= 'S' AND @disable_ind = 0  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 83231, 'Error Inserting lot_bin_ship record.  Order kit line is already shipped/posted'  
				RETURN  
			END  
		END  
  
		IF @i_qc_flag = 'Y' AND @i_qty != 0 AND @i_tran_code = 'Q'  
		BEGIN  
			SELECT @vend = vendor FROM inv_master (NOLOCK) WHERE part_no = @i_part_no  
			
			SELECT	@rcode = reason_code 
			FROM	ord_list (NOLOCK)  
			WHERE	order_no = @i_tran_no 
			AND		order_ext = 0 
			AND		line_no = @i_line_no  
  
			EXEC fs_enter_qc 'C' , @i_tran_no , @i_tran_ext, @i_line_no, @i_part_no ,  @i_location ,  @i_lot_ser ,   
						@i_bin_no , @i_qty , @vend ,   @i_who,  @rcode, @i_date_expires  
		END  
  
		IF @i_qc_flag != 'Y' AND @i_direction < 0  
		BEGIN  
			INSERT INTO lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code,   
						tran_no, tran_ext, date_tran, date_expires, qty, direction, cost, uom, uom_qty, conv_factor, line_no, who)  
			SELECT @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'S', @i_tran_no, @i_tran_ext,  
						@i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty , @i_conv_factor, @i_line_no, @i_who   
		END  
   
		IF @i_qc_flag != 'Y' AND @i_direction > 0 AND @i_tran_code IN ('S','T')  
		BEGIN  
			INSERT INTO lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code,     -- mls 10/31/00 SCR 24801 start  
					tran_no, tran_ext, date_tran, date_expires, qty, direction,    cost, uom, uom_qty, conv_factor, line_no, who)  
			SELECT @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'C', @i_tran_no, @i_tran_ext,     -- mls 7/27/01 SCR 27301  
					@i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty , @i_conv_factor, @i_line_no, @i_who   
		END  
  
		-- v1.0 
		/*
		FETCH NEXT FROM t700inslot__cursor into  
		@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,  
		@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,  
		@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @i_row_id, @i_kit_flag  
		*/

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@i_location = i_location, 
				@i_part_no = i_part_no, 
				@i_bin_no = i_bin_no, 
				@i_lot_ser = i_lot_ser, 
				@i_tran_code = i_tran_code, 
				@i_tran_no = i_tran_no, 
				@i_tran_ext = i_tran_ext, 
				@i_date_tran = i_date_tran, 
				@i_date_expires = i_date_expires, 
				@i_qty = i_qty, 
				@i_direction = i_direction, 
				@i_cost = i_cost, 
				@i_uom = i_uom, 
				@i_uom_qty = i_uom_qty, 
				@i_conv_factor = i_conv_factor, 
				@i_line_no = i_line_no, 
				@i_who = i_who, 
				@i_qc_flag = i_qc_flag, 
				@i_row_id = i_row_id, 
				@i_kit_flag = i_kit_flag
		FROM	#t700inslot
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

	END -- while  
  
	-- v1.0 CLOSE t700inslot__cursor  
	-- v1.0 DEALLOCATE t700inslot__cursor  
  
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 23/04/2015 - Performance Changes  
  
CREATE TRIGGER [dbo].[t700updlbship] ON [dbo].[lot_bin_ship]   
FOR UPDATE  
AS   
BEGIN  
  
	-- mls 1/16/01 SCR 25676 - rewrite trigger to improve performance  
  
	IF NOT (Update(location) or Update(part_no) or Update(bin_no) or Update(lot_ser) or    
		Update(qty) or Update(tran_no) or Update(tran_ext) or Update(direction) or Update(line_no) or  
		Update(uom_qty) or Update(conv_factor) or Update(qc_flag) or Update(tran_code))    
	BEGIN  
		RETURN  
	END  
  
	DECLARE @i_location varchar(10), @i_part_no varchar(30), @i_bin_no varchar(12),  
	@i_lot_ser varchar(25), @i_tran_code char(1), @i_tran_no int, @i_tran_ext int,  
	@i_date_tran datetime, @i_date_expires datetime, @i_qty decimal(20,8), @i_direction smallint,  
	@i_cost decimal(20,8), @i_uom char(2), @i_uom_qty decimal(20,8), @i_conv_factor decimal(20,8),  
	@i_line_no int, @i_who varchar(20), @i_qc_flag char(1), @i_row_id int, @i_kit_flag char(1),  
	@d_location varchar(10), @d_part_no varchar(30), @d_bin_no varchar(12),  
	@d_lot_ser varchar(25), @d_tran_code char(1), @d_tran_no int, @d_tran_ext int,  
	@d_date_tran datetime, @d_date_expires datetime, @d_qty decimal(20,8), @d_direction smallint,  
	@d_cost decimal(20,8), @d_uom char(2), @d_uom_qty decimal(20,8), @d_conv_factor decimal(20,8),  
	@d_line_no int, @d_who varchar(20), @d_qc_flag char(1), @d_row_id int, @d_kit_flag char(1)  
	  
	DECLARE @l_status char(1), @disable_ind int  

	SELECT @disable_ind = ISNULL((SELECT 1 FROM config (NOLOCK) WHERE flag = 'TRIG_LBS' AND value_str = 'DISABLE' ),0)  
  
	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int

	CREATE TABLE #t700updlot (
		row_id			int IDENTITY(1,1),
		i_location		varchar(10) NULL,
		i_part_no		varchar(30) NULL,
		i_bin_no		varchar(12) NULL,
		i_lot_ser		varchar(25) NULL,
		i_tran_code		char(1) NULL,
		i_tran_no		int NULL,
		i_tran_ext		int NULL,
		i_date_tran		datetime NULL,
		i_date_expires	datetime NULL,
		i_qty			decimal(20,8) NULL,
		i_direction		smallint NULL,
		i_cost			decimal(20,8) NULL,
		i_uom			char(2) NULL,
		i_uom_qty		decimal(20,8) NULL,
		i_conv_factor	decimal(20,8) NULL,
		i_line_no		int NULL,
		i_who			varchar(50) NULL,
		i_qc_flag		char(1) NULL,
		i_row_id		int NULL,
		i_kit_flag		char(1) NULL,
		d_location		varchar(10) NULL,
		d_part_no		varchar(30) NULL,
		d_bin_no		varchar(12) NULL,
		d_lot_ser		varchar(25) NULL,
		d_tran_code		char(1) NULL,
		d_tran_no		int	NULL,
		d_tran_ext		int NULL,
		d_date_tran		datetime NULL,
		d_date_expires	datetime NULL,
		d_qty			decimal(20,8) NULL,
		d_direction		smallint NULL,
		d_cost			decimal(20,8) NULL,
		d_uom			char(2) NULL,
		d_uom_qty		decimal(20,8) NULL,
		d_conv_factor	decimal(20,8) NULL,
		d_line_no		int NULL,
		d_who			varchar(50) NULL,
		d_qc_flag		char(1) NULL,
		d_row_id		int NULL,
		d_kit_flag		char(1) NULL)

	INSERT	#t700updlot (i_location, i_part_no, i_bin_no, i_lot_ser, i_tran_code, i_tran_no, i_tran_ext, i_date_tran, i_date_expires, 
				i_qty, i_direction, i_cost, i_uom, i_uom_qty, i_conv_factor, i_line_no, i_who, i_qc_flag, i_row_id, i_kit_flag,  
				d_location, d_part_no, d_bin_no, d_lot_ser, d_tran_code, d_tran_no, d_tran_ext, d_date_tran, d_date_expires, d_qty, 
				d_direction, d_cost, d_uom, d_uom_qty, d_conv_factor, d_line_no, d_who, d_qc_flag, d_row_id, d_kit_flag)
	-- v1.0 DECLARE t700updlot__cursor CURSOR LOCAL STATIC FOR  
	SELECT	i.location, i.part_no, i.bin_no, i.lot_ser, i.tran_code, i.tran_no, i.tran_ext,  
			i.date_tran, i.date_expires, i.qty, i.direction, i.cost, i.uom, i.uom_qty, i.conv_factor,  
			i.line_no, i.who, i.qc_flag, i.row_id, i.kit_flag,  
			d.location, d.part_no, d.bin_no, d.lot_ser, d.tran_code, d.tran_no, d.tran_ext,  
			d.date_tran, d.date_expires, d.qty, d.direction, d.cost, d.uom, d.uom_qty, d.conv_factor,  
			d.line_no, d.who, d.qc_flag, d.row_id, d.kit_flag  
	FROM	inserted i, deleted d  
	WHERE	i.row_id = d.row_id  
  
	-- v1.0 OPEN t700updlot__cursor  
	IF (@@ROWCOUNT = 0)
	BEGIN
		RETURN
	END  

	-- v1.0 if @@cursor_rows = 0  
	-- v1.0 begin  
	-- v1.0 CLOSE t700updlot__cursor  
	-- v1.0 DEALLOCATE t700updlot__cursor  
	-- v1.0 return  
	-- v1.0 end  
  
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@i_location = i_location, 
			@i_part_no = i_part_no, 
			@i_bin_no = i_bin_no, 
			@i_lot_ser = i_lot_ser, 
			@i_tran_code = i_tran_code, 
			@i_tran_no = i_tran_no, 
			@i_tran_ext = i_tran_ext, 
			@i_date_tran = i_date_tran, 
			@i_date_expires = i_date_expires, 
			@i_qty = i_qty, 
			@i_direction = i_direction, 
			@i_cost = i_cost, 
			@i_uom = i_uom, 
			@i_uom_qty = i_uom_qty, 
			@i_conv_factor = i_conv_factor, 
			@i_line_no = i_line_no, 
			@i_who = i_who, 
			@i_qc_flag = i_qc_flag, 
			@i_row_id = i_row_id, 
			@i_kit_flag = i_kit_flag,  
			@d_location = d_location, 
			@d_part_no = d_part_no, 
			@d_bin_no = d_bin_no, 
			@d_lot_ser = d_lot_ser, 
			@d_tran_code = d_tran_code, 
			@d_tran_no = d_tran_no, 
			@d_tran_ext = d_tran_ext, 
			@d_date_tran = d_date_tran, 
			@d_date_expires = d_date_expires, 
			@d_qty = d_qty, 
			@d_direction = d_direction, 
			@d_cost = d_cost, 
			@d_uom = d_uom, 
			@d_uom_qty = d_uom_qty, 
			@d_conv_factor = d_conv_factor, 
			@d_line_no = d_line_no, 
			@d_who = d_who, 
			@d_qc_flag = d_qc_flag, 
			@d_row_id = d_row_id, 
			@d_kit_flag = d_kit_flag
	FROM	#t700updlot
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	-- v1.0
	/*
	FETCH NEXT FROM t700updlot__cursor into  
	@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,  
	@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,  
	@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @i_row_id, @i_kit_flag,  
	@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,  
	@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,  
	@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @d_row_id, @d_kit_flag  
	  
	While @@FETCH_STATUS = 0  
	*/
	WHILE (@@ROWCOUNT <> 0)
	BEGIN  
		IF (@i_location != @d_location or @i_part_no != @d_part_no or @i_bin_no != @d_bin_no or  
			@i_lot_ser != @d_lot_ser or @i_qty != @d_qty or @i_tran_no != @d_tran_no or  
			@i_tran_ext != @d_tran_ext or @i_direction != @d_direction or  
			@i_line_no != @d_line_no or @i_uom_qty != @d_uom_qty or  
			@i_conv_factor != @d_conv_factor)  
		BEGIN  
			IF ISNULL(@i_kit_flag,'N') = 'N'  
			BEGIN  
				SELECT @l_status = ISNULL((SELECT status FROM ord_list l (NOLOCK) WHERE l.order_no = @i_tran_no AND l.order_ext = @i_tran_ext  
									AND l.line_no = @i_line_no AND l.part_no = @i_part_no AND l.location = @i_location),'')  
  
			    IF @l_status = ''  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 83231 ,'Error Updating lot_bin_ship record.  Order line for part does not exist'  
					RETURN  
				END  
				IF @l_status >= 'S' AND @disable_ind = 0  
				BEGIN  
					ROLLBACK tran  
					EXEC adm_raiserror 83231, 'Error Updating lot_bin_ship record.  Order line is already shipped/posted'  
					RETURN  
				END  
			END  
			ELSE  
			BEGIN  
				SELECT @l_status = ISNULL((SELECT status FROM ord_list_kit l (NOLOCK) WHERE l.order_no = @i_tran_no AND l.order_ext = @i_tran_ext  
									AND l.line_no = @i_line_no AND l.part_no = @i_part_no AND l.location = @i_location),'')    
				IF @l_status = ''  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 83231, 'Error Updating lot_bin_ship record.  Order kit line for part does not exist'  
					RETURN  
				END  
				IF @l_status >= 'S' AND @disable_ind = 0  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 83231, 'Error Updating lot_bin_ship record.  Order kit line is already shipped/posted'  
					RETURN  
				END  
			END  
		END  
  
		SELECT	@i_tran_code = CASE WHEN @i_direction < 0 THEN 'S'   
								WHEN @i_tran_code IN ('S','T') THEN 'S' 
								ELSE @i_tran_code END,   
				@d_tran_code = CASE WHEN @d_direction < 0 THEN 'S'   
								WHEN @d_tran_code IN ('S','T') THEN 'S' 
								ELSE @d_tran_code END  
  
		IF (@i_location != @d_location or @i_part_no != @d_part_no or @i_bin_no != @d_bin_no or  
			@i_lot_ser != @d_lot_ser or @i_qty != @d_qty or @i_tran_no != @d_tran_no or  
			@i_tran_ext != @d_tran_ext or @i_direction != @d_direction or  
			@i_line_no != @d_line_no or @i_uom_qty != @d_uom_qty or  
			@i_tran_code != @d_tran_code or  
			@i_conv_factor != @d_conv_factor or @i_qc_flag != @d_qc_flag) and  
			(@i_qc_flag != 'Y' or @d_qc_flag != 'Y')  
		BEGIN  
           
			IF @d_qc_flag != 'Y' AND @d_direction < 0  
			BEGIN  
				INSERT INTO lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code,   
					tran_no, tran_ext, date_tran, date_expires, qty, direction,   
					cost, uom, uom_qty, conv_factor, line_no, who)  
				SELECT	@d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'S', @d_tran_no, @d_tran_ext,  
					@d_date_tran, @d_date_expires, (@d_qty * -1), @d_direction, @d_cost,  
					@d_uom, (@d_uom_qty * -1), @d_conv_factor, @d_line_no, @d_who  
			END  
			IF @i_qc_flag != 'Y' AND @i_direction < 0  
			BEGIN       
				INSERT INTO lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code,   
					tran_no, tran_ext, date_tran, date_expires, qty, direction,   
					cost, uom, uom_qty, conv_factor, line_no, who)  
				SELECT @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'S', @i_tran_no, @i_tran_ext,  
					@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost,  
					@i_uom, @i_uom_qty, @i_conv_factor, @i_line_no, @i_who  
			END  
			IF @d_qc_flag != 'Y' AND @d_direction > 0 AND @d_tran_code in ('S','T')  
			BEGIN  
				INSERT INTO lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code,   
					tran_no, tran_ext, date_tran, date_expires, qty, direction,   
					cost, uom, uom_qty, conv_factor, line_no, who)  
				SELECT @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'C', @d_tran_no, @d_tran_ext,  -- mls 7/27/01 SCR 27301  
					@d_date_tran, @d_date_expires, (@d_qty * -1), @d_direction, @d_cost,  
					@d_uom, (@d_uom_qty * -1), @d_conv_factor, @d_line_no, @d_who  
			END  
			IF @i_qc_flag != 'Y' AND @i_direction > 0 AND @i_tran_code in ('S','T')  
			BEGIN  
				INSERT INTO lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code,   
					tran_no, tran_ext, date_tran, date_expires, qty, direction,   
					cost, uom, uom_qty, conv_factor, line_no, who)  
				SELECT @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'C', @i_tran_no, @i_tran_ext,  -- mls 7/27/01 SCR 27301  
					@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost,  
					@i_uom, @i_uom_qty, @i_conv_factor, @i_line_no, @i_who  
			END  
		END  
  
		IF (@d_qty != @i_qty or @d_lot_ser != @i_lot_ser or @d_bin_no != @i_bin_no) and @i_qc_flag = 'Y' -- mls 3/29/02 SCR 28598  
		BEGIN  
			UPDATE	qc_results   
			SET		qc_qty = @i_qty, 
					lot_ser = @i_lot_ser, 
					bin_no = @i_bin_no   
			FROM	ord_list ol (NOLOCK)  
			WHERE	ol.order_no = @i_tran_no 
			AND		ol.order_ext = @i_tran_ext 
			AND		ol.line_no = @i_line_no 
			AND		qc_results.lot_ser = @d_lot_ser 
			AND     qc_results.bin_no = @d_bin_no 
			AND		qc_results.qc_no = ol.qc_no   
		END  
  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@i_location = i_location, 
				@i_part_no = i_part_no, 
				@i_bin_no = i_bin_no, 
				@i_lot_ser = i_lot_ser, 
				@i_tran_code = i_tran_code, 
				@i_tran_no = i_tran_no, 
				@i_tran_ext = i_tran_ext, 
				@i_date_tran = i_date_tran, 
				@i_date_expires = i_date_expires, 
				@i_qty = i_qty, 
				@i_direction = i_direction, 
				@i_cost = i_cost, 
				@i_uom = i_uom, 
				@i_uom_qty = i_uom_qty, 
				@i_conv_factor = i_conv_factor, 
				@i_line_no = i_line_no, 
				@i_who = i_who, 
				@i_qc_flag = i_qc_flag, 
				@i_row_id = i_row_id, 
				@i_kit_flag = i_kit_flag,  
				@d_location = d_location, 
				@d_part_no = d_part_no, 
				@d_bin_no = d_bin_no, 
				@d_lot_ser = d_lot_ser, 
				@d_tran_code = d_tran_code, 
				@d_tran_no = d_tran_no, 
				@d_tran_ext = d_tran_ext, 
				@d_date_tran = d_date_tran, 
				@d_date_expires = d_date_expires, 
				@d_qty = d_qty, 
				@d_direction = d_direction, 
				@d_cost = d_cost, 
				@d_uom = d_uom, 
				@d_uom_qty = d_uom_qty, 
				@d_conv_factor = d_conv_factor, 
				@d_line_no = d_line_no, 
				@d_who = d_who, 
				@d_qc_flag = d_qc_flag, 
				@d_row_id = d_row_id, 
				@d_kit_flag = d_kit_flag
		FROM	#t700updlot
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
  
		-- v1.0
		/*
		FETCH NEXT FROM t700updlot__cursor into  
		@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,  
		@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,  
		@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @i_row_id, @i_kit_flag,  
		@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,  
		@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,  
		@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @d_row_id, @d_kit_flag  
		*/
	END -- while  
  
	-- v1.0 CLOSE t700updlot__cursor  
	-- v1.0 DEALLOCATE t700updlot__cursor  
  
END  
GO
ALTER TABLE [dbo].[lot_bin_ship] ADD CONSTRAINT [lot_bin_ship_kit_flag_cc1] CHECK (([kit_flag]='N' OR [kit_flag]='Y'))
GO
CREATE NONCLUSTERED INDEX [lbship2] ON [dbo].[lot_bin_ship] ([location], [part_no], [bin_no], [lot_ser], [tran_no], [tran_ext], [line_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [lbship1] ON [dbo].[lot_bin_ship] ([tran_no], [tran_ext], [line_no], [location], [part_no], [bin_no], [lot_ser]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lot_bin_ship] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_bin_ship] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_bin_ship] TO [public]
GO
GRANT DELETE ON  [dbo].[lot_bin_ship] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_bin_ship] TO [public]
GO

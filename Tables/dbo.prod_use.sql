CREATE TABLE [dbo].[prod_use]
(
[timestamp] [timestamp] NOT NULL,
[time_no] [int] NOT NULL,
[employee_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL,
[prod_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[project_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_date] [datetime] NOT NULL,
[plan_qty] [decimal] (20, 8) NOT NULL,
[used_qty] [decimal] (20, 8) NOT NULL,
[plan_pcs] [decimal] (20, 8) NOT NULL,
[pieces] [decimal] (20, 8) NOT NULL,
[shift] [int] NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scrap_pcs] [decimal] (20, 8) NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oper_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__prod_use__oper_s__1A0BBF15] DEFAULT ('N'),
[date_expires] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t510delproduse] ON [dbo].[prod_use] FOR DELETE AS
begin
if exists (select * from config where flag='TRIG_DEL_USE' and value_str='DISABLE')
   return
else
begin
   rollback tran
   exec adm_raiserror 76899, 'You Can Not Delete Production Usage Records!'
   return
end
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t510updproduse] ON [dbo].[prod_use] FOR UPDATE AS
BEGIN
if exists (select * from config where flag='TRIG_UPD_USE' and value_str='DISABLE')
   return
else
begin
   rollback tran
   exec adm_raiserror 76899 ,'You Can Not Update Production Usage Records!'
   return
end
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insproduse] ON [dbo].[prod_use] FOR insert AS 
BEGIN

DECLARE @i_time_no int, @i_employee_key varchar(10), @i_prod_no int, @i_prod_ext int,
@i_prod_part varchar(30), @i_location varchar(10), @i_seq_no varchar(4), @i_part_no varchar(30),
@i_project_key varchar(10), @i_status char(1), @i_tran_date datetime, @i_plan_qty decimal(20,8),
@i_used_qty decimal(20,8), @i_plan_pcs decimal(20,8), @i_pieces decimal(20,8), @i_shift int,
@i_who_entered varchar(20), @i_date_entered datetime, @i_void char(1), @i_void_who varchar(20),
@i_void_date datetime, @i_note varchar(255), @i_scrap_pcs decimal(20,8), @i_lot_ser varchar(25),
@i_bin_no varchar(12), @i_oper_status char(1), @i_date_expires datetime

declare @dir int, @fgpart varchar(30), @lno int, @lrow int, @p_line int, @adj_pcs decimal(20,8),
  @costpct decimal(20,8), @pstat char(1), @planqty decimal(20,8), @max int,
  @ppcs decimal(20,8), @prod_type char(1), @fixed char(1), @p_pcs decimal(20,8),
  @ptype char(1), @p_qty decimal(20,8), @lb char(1), @serial int, @qc char(1),
  @vend varchar(10), @costpctnew decimal(20,8), @xlno int, @i_description varchar(255),
  @i_uom char(2), @lb_qty decimal(20,8), @pl_used_qty decimal(20,8)

DECLARE t700insprod_cursor CURSOR LOCAL STATIC FOR
SELECT i.time_no, i.employee_key, i.prod_no, i.prod_ext, i.prod_part, i.location, i.seq_no,
i.part_no, i.project_key, i.status, i.tran_date, i.plan_qty, i.used_qty, i.plan_pcs, i.pieces,
i.shift, i.who_entered, i.date_entered, i.void, i.void_who, i.void_date, i.note, i.scrap_pcs,
i.lot_ser, i.bin_no, i.oper_status, i.date_expires
from inserted i

OPEN t700insprod_cursor

if @@cursor_rows != 0
begin 
  declare @relaxed_lotbin char(1)								-- mls 12/13/02 SCR 30442 start
  select @relaxed_lotbin = isnull((select 'Y' from config (nolock) where flag = 'INV_LOT_BIN'
    and value_str = 'RELAXED'),'N')								-- mls 12/13/02 SCR 30442 end

  FETCH NEXT FROM t700insprod_cursor into
    @i_time_no, @i_employee_key, @i_prod_no, @i_prod_ext, @i_prod_part, @i_location, @i_seq_no,
    @i_part_no, @i_project_key, @i_status, @i_tran_date, @i_plan_qty, @i_used_qty, @i_plan_pcs,
    @i_pieces, @i_shift, @i_who_entered, @i_date_entered, @i_void, @i_void_who, @i_void_date,
    @i_note, @i_scrap_pcs, @i_lot_ser, @i_bin_no, @i_oper_status, @i_date_expires

  While @@FETCH_STATUS = 0
  begin
    SELECT @dir=isnull(prod_list.direction,-1), @lno = isnull(prod_list.line_no,0),			-- mls 4/11/00 SCR 21414 start
      @costpct=cost_pct, @ppcs=p_pcs, @ptype=part_type, @planqty=prod_list.plan_qty
    FROM prod_list (nolock)									
    WHERE prod_list.prod_no = @i_prod_no and	prod_list.prod_ext = @i_prod_ext and 
      prod_list.seq_no = @i_seq_no and prod_list.part_no = @i_part_no and prod_list.line_no > 0			

    -- If we did not find what we were looking for, default values
    IF @@rowcount <= 0 
    BEGIN
      SELECT @dir = -1, @lno = 0

      if (SELECT count(*) FROM prod_list (nolock)	
	  WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext and seq_no = @i_seq_no and line_no <= 0 ) > 0 
      begin											
	 rollback tran
	 exec adm_raiserror 86501, 'No Finished Good open result found.'
	 return
      end
    END												-- mls 4/11/00 SCR 21414 end

    SELECT @fgpart = part_no, @pstat = status,
      @prod_type = prod_type							-- mls 4/17/01 SCR 26742
    FROM produce_all (nolock)								-- mls 4/11/00 SCR 21414			
    WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext 			-- mls 4/11/00 SCR 21414

    if @fgpart = @i_part_no and isnull(@i_seq_no,'') = ''
    begin
      if (@i_pieces != 0 or @i_scrap_pcs != 0)							-- mls 4/11/00 SCR 21414 start
      begin											
        UPDATE produce_all
        SET qty = qty + @i_pieces,									
            scrapped = scrapped + @i_scrap_pcs							
        WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext 								
      end											-- mls 4/11/00 SCR 21414 end
      SELECT @lno = 1
    end 

    if @i_oper_status = 'S' 
    begin
      -- closing this operation short 
      UPDATE prod_list
      SET oper_status = 'S'
      WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext and seq_no = @i_seq_no and direction < 0

      -- close the previous operations if they are open
      select @lrow = IsNull((select line_no from prod_list						-- mls 2/23/01 SCR 26073 start
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext and seq_no = @i_seq_no and direction < 0),0)
      select @p_line = isnull((select p_line from prod_list 						
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lrow),0)

      update prod_list										
      set oper_status = 'X'
      where prod_no = @i_prod_no and prod_ext = @i_prod_ext and (p_line < @p_line or
        (p_line = @p_line and seq_no < @i_seq_no) or 
        (p_line = @p_line and seq_no = @i_seq_no and line_no < @lrow)) and
        oper_status = 'N' and direction < 0 and line_no > 1						-- mls 2/23/01 SCR 26073 end
        
      -- need to adjust the qty_scheduled in the produce table, and the planned pieces,
      -- so that the scheduler can recalculate
      select @adj_pcs = (pieces + @i_pieces) 
      from prod_list
      where prod_no = @i_prod_no and prod_ext = @i_prod_ext and seq_no = @i_seq_no

      if @adj_pcs > 0 
      begin
        -- adjust the qty_scheduled amount in the produce table
        update produce_all 
        set qty_scheduled = @adj_pcs 
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext 

        update prod_list 
        set plan_qty = @adj_pcs 
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext and direction = 1

        select @planqty = @adj_pcs

        -- adjust the remaining prod_list rows with the new planned pieces and
        -- quantities
        -- @max is the number of lines; @lrow is the row being adjusted
        select @max = max(line_no) from prod_list
          where prod_no = @i_prod_no and prod_ext = @i_prod_ext
        select @lrow = IsNull(( select line_no from prod_list
          where prod_no=@i_prod_no and prod_ext=@i_prod_ext and	seq_no= @i_seq_no),0)

        while (@lrow < @max) and (@lrow > 0) 
        begin
          select @fixed = 'N'	-- assume not fixed

          select @lrow = @lrow+1	-- start at the next row
          select @p_pcs = p_pcs, @p_qty = p_qty, @fixed = fixed	-- rev 3:  get the fixed from the prod_list
          from prod_list
          where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lrow

          if (@fixed = 'N')	-- adjust the plan pieces and plan qty
            update prod_list 
            set plan_pcs = @adj_pcs * @p_pcs,
		plan_qty = @adj_pcs * @p_qty 
            where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lrow

          if (@fixed = 'Y')	-- only adjust the pieces going forward
            if (@p_pcs > 0)
              update prod_list 
              set plan_pcs = @adj_pcs * @p_pcs
              where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lrow

          if (@p_pcs = 0)	-- default to 1 if pieces not set
	    update prod_list 
            set plan_pcs = @adj_pcs
            where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lrow
        end
      end
    end

    -- If they are closing this operation, close all previous
    if @i_oper_status = 'X'
    
    BEGIN											-- mls 4/11/00 SCR 21414
      UPDATE prod_list
      SET oper_status = 'X'
      WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext and seq_no = @i_seq_no and direction < 0

      -- close the previous operations if they are open
      select @lrow = IsNull((select line_no from prod_list						-- mls 2/23/01 SCR 26073 start
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext and seq_no = @i_seq_no and direction < 0),0)
      select @p_line = isnull((select p_line from prod_list 						
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lrow),0)

      update prod_list										
      set oper_status = 'X'
      where prod_no = @i_prod_no and prod_ext = @i_prod_ext and (p_line < @p_line or
       (p_line = @p_line and seq_no < @i_seq_no) or 
       (p_line = @p_line and seq_no = @i_seq_no and line_no < @lrow)) and
       oper_status = 'N' and direction < 0 and line_no > 1						-- mls 2/23/01 SCR 26073 end
    END											-- mls 4/11/00 SCR 21414

    -- If they are opening this operation, open all following
    if @i_oper_status = 'N'
    BEGIN											-- mls 4/11/00 SCR 21414
      select @lrow = IsNull((select line_no from prod_list						-- mls 2/23/01 SCR 26073 start
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext and seq_no = @i_seq_no and direction < 0),0)
      select @p_line = isnull((select p_line from prod_list 						
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lrow),0)

      update prod_list										
      set oper_status = 'N'
      where prod_no = @i_prod_no and prod_ext = @i_prod_ext and (p_line > @p_line or
        (p_line = @p_line and seq_no > @i_seq_no) or 
        (p_line = @p_line and seq_no = @i_seq_no and line_no > @lrow)) and
        oper_status != 'N' and direction < 0 and line_no > 1						-- mls 2/23/01 SCR 26073 end
    END											-- mls 4/11/00 SCR 21414  

    if @ptype = 'X' and @dir < 0 and @prod_type = 'J'					-- mls 4/17/01 SCR 26742 start
      select @lb = 'N', @serial = 0, @qc = 'N'
    else
    begin											-- mls 4/17/01 SCR 26742 end
      SELECT @lb = isnull(lb_tracking,'N'), 
        @serial = isnull(serial_flag,0),
        @qc=isnull(qc_flag,'N'), @vend=vendor,
        @i_description = description,
        @i_uom = uom
      FROM inv_master (nolock)								
      WHERE part_no = @i_part_no							

      -- If we did not find what we were looking for, default values
      IF @@rowcount <= 0
      begin											
        rollback tran
        exec adm_raiserror 991021, 'Part does not exist in inventory.'
        return
      end
    end

    IF @dir < 0 select @qc = 'N'								-- mls 4/11/00 

    if @lb = 'Y' and @serial = 1 and @dir > 0 						-- mls 2/26/01 SCR 26060 start
      and @relaxed_lotbin = 'N'								-- mls 12/13/02 SCR 30442
    begin
      if @i_pieces > 1
      begin
        rollback tran
        exec adm_raiserror 991021, 'Qty cannot exceed 1 from serial tracked part.'
        return
      end
      if exists (select 1 from lot_bin_stock where part_no = @i_part_no and location = @i_location and 
        lot_ser = @i_lot_ser and qty > 0)
      begin
        rollback tran
        exec adm_raiserror 991021, 'Qty cannot exceed 1 from serial tracked part.'
        return
      end
      if exists (select 1 from lot_bin_prod where tran_no = @i_prod_no and tran_ext = @i_prod_ext
        and part_no = @i_part_no and location = @i_location and lot_ser = @i_lot_ser and direction > 0 and qc_flag = 'Y')
      begin
        rollback tran
        exec adm_raiserror 991021, 'Qty cannot exceed 1 from serial tracked part.'
        return
      end
    end											-- mls 2/26/01 SCR 26060 end

    if @lno > 0 
    begin
      
      IF @qc='Y' and @dir > 0 
      begin 	
        
        
        	
        if @planqty != 0 select @costpctnew=@costpct * @i_pieces / @planqty
        else select @costpctnew=0
         	
        if @i_pieces > @planqty select @costpctnew=@costpct
	
        SELECT @xlno=isnull((select min(line_no)						-- mls 4/11/00 SCR 21414
        FROM prod_list (nolock)							
        WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no < 0),0) -1

        select @lb_qty = @i_pieces - @i_scrap_pcs					-- mls 11/04/03 SCR 32077

        IF @lb = 'Y' and @relaxed_lotbin = 'N' and @lb_qty != 0				-- mls 12/13/02 SCR 30442
        BEGIN 	
          INSERT lot_bin_prod (
            location       , part_no        , bin_no         , 
            lot_ser        , tran_code      , tran_no        , 
            tran_ext       , date_tran      , date_expires   , 
            qty            , direction      , cost           , 
            uom            , uom_qty        , conv_factor    , 
            line_no        , who            , qc_flag        )		-- mls 2/23/01 SCR 26060   
          SELECT @i_location, @i_part_no, @i_bin_no,							-- mls 4/11/00 SCR 21414
            @i_lot_ser, case when @lb_qty < 0 then 'S' else @pstat end , @i_prod_no,							
            @i_prod_ext, @i_tran_date, isnull(@i_date_expires,getdate()) ,		-- mls 6/25/02 SCR 29082
            @lb_qty , @dir , 0 , '' , @lb_qty, 1.0 ,								
            @xlno , @i_who_entered, case when @lb_qty < 0 then 'N' else @qc end		-- mls 2/23/01 SCR 26060									
        END

        INSERT prod_list 
	  ( prod_no,       prod_ext,      line_no,      seq_no,
	  part_no,       location,      description,
          plan_qty,      used_qty,      uom,
          conv_factor,   who_entered,   note,
          lb_tracking,   bench_stock,   status,
          constrain,     plan_pcs,      pieces,
          scrap_pcs,     direction,     cost_pct,
          p_qty,         p_line,        p_pcs,
          qc_no,         oper_status,   part_type, attrib, last_tran_date)			-- mls 4/13/00 SCR 22566
        SELECT @i_prod_no, @i_prod_ext, @xlno, @i_seq_no,					-- mls 4/11/00 SCR 21414	
          @i_part_no, @i_location, i.description, @i_pieces, @i_pieces, i.uom,									
          1.0, @i_employee_key, 'Operation Added From Production Usage Entry',			
          i.lb_tracking, 'N', 
          case when @i_pieces <= 0 or @lb_qty = 0 then 'S' else 'R' end,			-- mls 11/13/03 SCR 32108
												-- mls 5/30/03 SCR 31266							
          'N', @i_pieces, @i_pieces, @i_scrap_pcs, @dir, @costpctnew, 0, 0, @ppcs,
          0, @i_oper_status, @ptype,	0, @i_tran_date						-- mls 4/13/00 SCR 22566
        FROM inv_master i (nolock)								
        WHERE i.part_no = @i_part_no and @i_prod_no > 0						

        

        UPDATE prod_list								-- mls 4/11/00 SCR 21414
        SET plan_qty = plan_qty - @i_pieces,					 
          cost_pct=cost_pct - @costpctnew,
          last_tran_date = @i_tran_date								-- mls 4/13/00 SCR 22566
        WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext and seq_no = @i_seq_no and line_no=@lno 						
      end 
      ELSE	
      begin
        select @pl_used_qty = used_qty
        from prod_list (nolock)
        where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lno

        
        if @lb = 'Y' and @qc != 'Y' and @relaxed_lotbin = 'N'					-- mls 12/13/02 SCR 30442
        begin
          IF EXISTS (SELECT 1 FROM lot_bin_prod l (nolock)						-- mls 4/11/00 SCR 21414
	    WHERE l.tran_no = @i_prod_no and l.tran_ext = @i_prod_ext and l.line_no=@lno and										
            l.location = @i_location and part_no = @i_part_no and l.bin_no = @i_bin_no and l.lot_ser = @i_lot_ser)					
          BEGIN 
            if @dir < 0 
            begin
              UPDATE lot_bin_prod									-- mls 4/11/00 SCR 21414
              SET lot_bin_prod.uom_qty = lot_bin_prod.uom_qty + @i_used_qty,				
                lot_bin_prod.qty = lot_bin_prod.qty + @i_used_qty,
				date_tran = @i_tran_date							-- mls 3/5/07 				
              WHERE tran_no = @i_prod_no and tran_ext = @i_prod_ext and line_no=@lno and										
                location = @i_location and part_no = @i_part_no and bin_no = @i_bin_no and lot_ser = @i_lot_ser
            end
            if @dir > 0 
            begin
              UPDATE lot_bin_prod									-- mls 4/11/00 SCR 21414
              SET lot_bin_prod.uom_qty = lot_bin_prod.uom_qty + (@i_used_qty - @i_scrap_pcs),	
                lot_bin_prod.qty = lot_bin_prod.qty + (@i_used_qty - @i_scrap_pcs),
				date_tran = @i_tran_date							-- mls 3/5/07 				
	      WHERE tran_no = @i_prod_no and tran_ext = @i_prod_ext and line_no=@lno and										
                location = @i_location and part_no = @i_part_no and bin_no = @i_bin_no and lot_ser = @i_lot_ser
            end
          END 
          ELSE
          BEGIN 
            if @dir < 0 
            begin	
              INSERT lot_bin_prod (									-- mls 4/11/00 SCR 21414
              location , part_no , bin_no , 
              lot_ser , tran_code , tran_no , 
              tran_ext , date_tran , date_expires , 
              qty , direction , cost , 
              uom , uom_qty , conv_factor , 
              line_no , who ) 
              SELECT @i_location, @i_part_no, @i_bin_no,								
                @i_lot_ser, @pstat, @i_prod_no,									
                @i_prod_ext, @i_tran_date, isnull(@i_date_expires,getdate()) ,					-- mls 6/25/02 SCR 29082
                @i_used_qty , @dir	 , 0 ,								
                '' , @i_used_qty , 1.0 ,								
                @lno , @i_who_entered 										
            end
            if @dir > 0 
            begin	
              INSERT lot_bin_prod (									-- mls 4/11/00 SCR 21414
                location , part_no , bin_no , 
                lot_ser , tran_code , tran_no , 
                tran_ext , date_tran , date_expires , 
                qty , direction , cost , 
                uom , uom_qty , conv_factor , 
                line_no , who , qc_flag)								-- mls 2/23/01 SCR 26060 
              SELECT @i_location, @i_part_no, @i_bin_no ,								
                @i_lot_ser , @pstat , @i_prod_no ,								
                @i_prod_ext, @i_tran_date, isnull(@i_date_expires,getdate()) ,					-- mls 6/25/02 SCR 29082
                (@i_used_qty - @i_scrap_pcs) , @dir , 0 ,						
                '' , (@i_used_qty - @i_scrap_pcs) , 1.0 ,						
                @lno , @i_who_entered	, @qc									-- mls 2/23/01 SCR 26060									
            end
          end 
        end 

        	
        if @dir < 0 
        begin
          UPDATE prod_list									-- mls 4/11/00 SCR 21414
          SET used_qty = @pl_used_qty + @i_used_qty,				
	    pieces = pieces + @i_pieces,						
  	    scrap_pcs = scrap_pcs + @i_scrap_pcs,
            last_tran_date = @i_tran_date								-- mls 4/13/00 SCR 22566
          WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lno
        end

        if @dir > 0 
        begin
          UPDATE prod_list									-- mls 4/11/00 SCR 21414
          SET used_qty = @pl_used_qty + @i_pieces,					
  	    pieces = pieces + @i_pieces,						
	    scrap_pcs = scrap_pcs + @i_scrap_pcs,
            last_tran_date = @i_tran_date								-- mls 4/13/00 SCR 22566
          WHERE prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lno
        end

      end 
    end 
    else 
    begin  
      if @i_prod_no > 0 and @i_seq_no <> ''
      begin
        if not exists( select 1 from prod_list (nolock)						-- mls 4/11/00 SCR 21414
        where prod_list.prod_no = @i_prod_no and prod_list.prod_ext = @i_prod_ext and 								
        prod_list.seq_no = @i_seq_no)											
        begin
          SELECT @lno=isnull(max(line_no),0) + 1
          FROM prod_list p 
          WHERE p.prod_no = @i_prod_no and p.prod_ext = @i_prod_ext										

  
          INSERT prod_list 
            ( prod_no,       prod_ext,      line_no,      seq_no,
            part_no,       location,      description,
            plan_qty,      used_qty,      uom,
            conv_factor,   who_entered,   note,
            lb_tracking,   bench_stock,   status,
            constrain,     plan_pcs,      pieces,
            scrap_pcs,     direction,     cost_pct,
            p_qty,         p_line,        p_pcs,
            qc_no,         oper_status,	  part_type,
            attrib,
	    last_tran_date)						-- mls 4/13/00 SCR 22566
          SELECT @i_prod_no, @i_prod_ext, @lno, @i_seq_no,									-- mls 4/11/00 SCR 21414
            @i_part_no, @i_location, @i_description,									
            @i_plan_qty, 0, @i_uom,								
            1.0, @i_employee_key, 'Operation Added From Production Usage Entry',				
            @lb, 'N', 'P','N', @i_plan_pcs, @i_pieces,									
            @i_scrap_pcs, @dir, 0, 0, 0, 0,
            0, @i_oper_status, 'P', 0,
	    @i_tran_date								-- mls 4/13/00 SCR 22566


          
          if @lb = 'Y'  and @relaxed_lotbin = 'N'					-- mls 12/13/02 SCR 30442
          begin
            INSERT lot_bin_prod (
                    location       , part_no        , bin_no         , 
                    lot_ser        , tran_code      , tran_no        , 
                    tran_ext       , date_tran      , date_expires   , 
                    qty            , direction      , cost           , 
                    uom            , uom_qty        , conv_factor    , 
                    line_no        , who                                )   
            SELECT @i_location, @i_part_no, @i_bin_no,								-- mls 4/11/00 SCR 21414	
              @i_lot_ser, @pstat, @i_prod_no,									
              @i_prod_ext, @i_tran_date, isnull(@i_date_expires,getdate()) ,					-- mls 6/25/02 SCR 29082
              @i_used_qty, -1 , 0 ,									
              '' , @i_used_qty, 1.0 ,									
              @lno , @i_who_entered 										
          end 

          update prod_list
          set used_qty = @i_used_qty
          where prod_no = @i_prod_no and prod_ext = @i_prod_ext and line_no = @lno
            and seq_no = @i_seq_no
        end 
      end
    end

    FETCH NEXT FROM t700insprod_cursor into
      @i_time_no, @i_employee_key, @i_prod_no, @i_prod_ext, @i_prod_part, @i_location, @i_seq_no,
      @i_part_no, @i_project_key, @i_status, @i_tran_date, @i_plan_qty, @i_used_qty, @i_plan_pcs,
      @i_pieces, @i_shift, @i_who_entered, @i_date_entered, @i_void, @i_void_who, @i_void_date,
      @i_note, @i_scrap_pcs, @i_lot_ser, @i_bin_no, @i_oper_status, @i_date_expires
  end -- while
end

CLOSE t700insprod_cursor
DEALLOCATE t700insprod_cursor

END
GO
CREATE NONCLUSTERED INDEX [produse3] ON [dbo].[prod_use] ([employee_key], [status], [tran_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [produse2] ON [dbo].[prod_use] ([employee_key], [tran_date]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [produse1] ON [dbo].[prod_use] ([time_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prod_use] TO [public]
GO
GRANT SELECT ON  [dbo].[prod_use] TO [public]
GO
GRANT INSERT ON  [dbo].[prod_use] TO [public]
GO
GRANT DELETE ON  [dbo].[prod_use] TO [public]
GO
GRANT UPDATE ON  [dbo].[prod_use] TO [public]
GO

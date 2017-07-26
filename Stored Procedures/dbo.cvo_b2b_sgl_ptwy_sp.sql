SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*

Process Single Piece putaways scanned by the Ipod brigade

8700T212D40242c

uSAGE:
exec cvo_b2b_sgl_ptwy_sp 

SELECT * FROM dbo.cvo_b2b_xfer_log AS bxl
select * From cvo_single_piece_log order by id desc

update cvo_single_piece_log set flag = 'Ready' where flag = 'error'

*/

CREATE procedure [dbo].[cvo_b2b_sgl_ptwy_sp] 

as 
-- use cvo
set nocount ON
SET ANSI_WARNINGS off

declare @id int, @valid int, @scan varchar(20), @today datetime
declare @location varchar(10),  @from_bin varchar(10), @to_bin varchar(10), @qty DECIMAL(20,0)
declare @part_no varchar(40),   @bin_qty decimal(20,0)

SELECT @today = GETDATE()

IF (SELECT OBJECT_ID('tempdb..#adm_bin_xfer')) IS NOT NULL 
BEGIN   
  DROP TABLE #adm_bin_xfer  
END

CREATE TABLE #adm_bin_xfer 
(issue_no	int null,
location	varchar (10)	not null,
part_no		varchar (30)	not null,
lot_ser		varchar (25)	not null,
bin_from	varchar (12)	not null,
bin_to		varchar (12)	not null,
date_expires datetime		not null,
qty			decimal(20,8)	not null,
who_entered	varchar(50)	not null,
reason_code	varchar (10)	null,
err_msg		varchar (255)	null,
row_id		int identity	not null)


IF (SELECT OBJECT_ID('dbo.cvo_b2b_xfer_log')) IS NULL 
begin
	CREATE TABLE dbo.cvo_b2b_xfer_log
	(issue_no	int null,
	location	varchar (10)	not null,
	part_no		varchar (30)	not null,
	lot_ser		varchar (25)	not null,
	from_bin	varchar (12)	not null,
	to_bin		varchar (12)	not null,
	date_expires datetime		not null,
	qty			decimal(20,8)	not null,
	who_entered	varchar(50)	not null,
	reason_code	varchar (10)	null,
	err_msg		varchar (255)	null,
	row_id		int 	not null,
	date_tran   datetime null)

	grant all on dbo.cvo_b2b_xfer_log to public
	-- select * From  dbo.cvo_b2b_xfer_log
end

--

IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NOT NULL 
BEGIN   
DROP TABLE #temp_who  
END
Create table #temp_who(who varchar(50), login_id varchar(50))
Insert #temp_who select 'tdcsql','tdcsql'


/*  Set up adhoc - in TO BIN = Transfer*/

IF (SELECT OBJECT_ID('tempdb..#temp_part_list')) IS NOT NULL 
BEGIN  
DROP TABLE #temp_part_list
END

CREATE TABLE #temp_part_list
(
    id INT,
    part_no VARCHAR(30) NOT NULL,
    qty DECIMAL(20, 8) NOT NULL,
    location VARCHAR(12),
    from_bin VARCHAR(10),
    to_bin VARCHAR(10)
)

--


IF NOT EXISTS (SELECT 1 FROM dbo.cvo_single_piece_log AS spl 
				WHERE flag = 'ready' AND procTime IS null)
begin 
		INSERT INTO dbo.cvo_b2b_xfer_log
		(
			issue_no,
			location,
			part_no,
			lot_ser,
			from_bin,
			to_bin,
			date_expires,
			qty,
			who_entered,
			reason_code,
			err_msg,
			row_id,
			date_tran
		)
select null, '', '', '', '', '', @today, 0, 'tdcsql','NO Data', ' No Scans to process. ', 0,@today
return 
end

-- start validation and processing


select @id = min(s.id) from dbo.cvo_single_piece_log AS s WHERE flag = 'Ready' AND proctime IS null

while @id is not null
begin
	
	select @scan = s.part_no, @from_bin = s.from_bin, @to_bin = to_bin, @qty = s.qty, @location = location
		 from dbo.cvo_single_piece_log  s where @id = s.id
	
	-- check to see if the part or upc code exists
	set @valid = 1
	if not exists (select 1 from inv_master where upc_code = @scan ) and  
	   not exists (select 1 from inv_master where part_no = @scan) 
	begin 
				INSERT INTO dbo.cvo_b2b_xfer_log
		(
			issue_no,
			location,
			part_no,
			lot_ser,
			from_bin,
			to_bin,
			date_expires,
			qty,
			who_entered,
			reason_code,
			err_msg,
			row_id,
			date_tran
		)
		select @id, @location, part_no, '', @from_bin, @to_bin, ISNULL(addTime,@today), 0, 
		'tdcsql','InvalidUPC', ' Upc code or part number not found. ', 0, @today
		from dbo.cvo_single_piece_log where id = @id
	    set @valid = 0
	end

	if @valid = 1
	insert into #temp_part_list
		select @id, i.part_no, @qty , @location, @from_bin, @to_bin from inv_master i (nolock) 
		where i.upc_code = @scan
		union all
		select @id, i.part_no, @qty , @location, @from_bin, @to_bin from inv_master i (nolock) 
		where i.part_no = @scan 
	
	-- check that the part is in the from bin

	if (not exists 
		(select 1 from lot_bin_stock lb 
		JOIN #temp_part_list t 
		on lb.part_no = t.part_no and lb.location = t.location
		and lb.bin_no = t.from_bin and t.id = @id) )
        BEGIN
		 		INSERT INTO dbo.cvo_b2b_xfer_log
		(
			issue_no,
			location,
			part_no,
			lot_ser,
			from_bin,
			to_bin,
			date_expires,
			qty,
			who_entered,
			reason_code,
			err_msg,
			row_id,
			date_tran
		)
		 select id, location, part_no, '', from_bin, to_bin, ISNULL(addTime, @today), qty, 
			   'tdcsql','InvalidBin', 'Scanned item not in from bin/location. ', 0, @today
	    	from dbo.cvo_single_piece_log where id = @id
		 DELETE from #temp_part_list where id = @id
		 UPDATE dbo.cvo_single_piece_log SET flag = 'Error'	WHERE id = @id
		end
		ELSE -- good to go
		begin
		 UPDATE dbo.cvo_single_piece_log SET flag = 'Processed', procTime = @today
				WHERE id = @id
		end
		
	select @id = min(s.id) from dbo.cvo_single_piece_log AS s 
	 WHERE flag = 'Ready' AND proctime IS NULL and s.id > @id
end


--select * From #scandata
--select * from #temp_part_list

-- summarize the list of scans so there is one per part 

IF (SELECT OBJECT_ID('tempdb..#t1')) IS NOT NULL 
BEGIN   
  DROP TABLE #t1  
END

select max(id) id, part_no, sum(qty) qty, location , from_bin, to_bin
into #t1
from #temp_part_list
group by part_no, location, from_bin, to_bin
ORDER BY max(ID)

truncate table #temp_part_list

insert into #temp_part_list
 select id, part_no, qty, location, from_bin, to_bin 
 FROM #t1

--	LOOP HERE UNTIL TEMP_PART_LIST IS EMPTY
select @id = min(id) from #temp_part_list
-- select @id

while @id is not null
-- TESTING 
-- AND @ID <=300
	begin
		select @part_no = part_no,
				@qty = qty,
				@location = location,
				@from_bin = from_bin,
				@to_bin = to_bin
		from #temp_part_list where id = @id
	
	select @bin_qty = sum(lb.qty) from lot_bin_stock lb (nolock) where lb.part_no = @part_no
		and lb.location = @location and lb.bin_no = @from_bin
		
	if (@bin_qty < @qty)
	begin
		insert into cvo_b2b_xfer_log
		select @id, @location, @part_no, '', @from_bin, @to_bin, @today, @qty, 'tdcsql','BinQTY', 
	'Not enough stock. Only '+ convert(varchar(10),@bin_qty) +' transferred.', 0, @today
		select @qty = @bin_qty
	end
	truncate table #adm_bin_xfer
	INSERT INTO #adm_bin_xfer 
	(issue_no, location, part_no, lot_ser, bin_from, bin_to, date_expires, qty, who_entered, reason_code, err_msg)
	values (NULL,@location,@part_no,'1',@from_bin,@to_bin,convert(varchar(12),
		dateadd(yy,1,@today),109),@qty,'tdcsql',NULL,NULL)
	begin transaction
		exec tdc_bin_xfer
	commit transaction

		INSERT INTO dbo.cvo_b2b_xfer_log
		(
			issue_no,
			location,
			part_no,
			lot_ser,
			from_bin,
			to_bin,
			date_expires,
			qty,
			who_entered,
			reason_code,
			err_msg,
			row_id,
			date_tran
		)
	SELECT
		issue_no,
		location,
		part_no,
		lot_ser,
		bin_from,
		bin_to,
		ISNULL(date_expires, @today),
		qty,
		who_entered,
		reason_code,
		err_msg,
		row_id,
		@today date_tran
	FROM #adm_bin_xfer
	;
	-- where issue_no = null -- errors only

	select @id = min(id) from #temp_part_list where id > @id
end

GO

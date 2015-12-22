SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*

Bin - Bin Transfer from upc scans list
defaults to from-bin = rr refurb, to-bin = rr putaway
makes parts available for single frame putaway, and manual allocation in an emergency.

8700T212D40242c

uSAGE:
exec cvo_b2b_xfer_sp 

SELECT * FROM CVO_B2B_XFER_LOG where date_tran >= dateadd(dd, datediff(dd,0,getdate()), 0)
select * from cvo_upc_scandata
select * from cvo_upc_scandata_processed

truncate table cvo_upc_scandata
truncate table cvo_upc_scandata_processed
truncate table cvo_b2b_xfer_log

TO CREATE TEST DATA:

INSERT INTO CVO_UPC_SCANDATA
SELECT TOP 50 UPC_CODE, GETDATE(), 'RRR2RRP' FROM INV_MASTER i
, lot_bin_stock lb  
WHERE i.UPC_CODE IS NOT NULL 
and i.type_code in ('frame','sun') and i.part_no = lb.part_no
and lb.bin_no = 'rr refurb'

INSERT INTO CVO_UPC_SCANDATA
SELECT TOP 50 UPC_CODE, GETDATE(), 'RRR2RRP' FROM INV_MASTER i
, lot_bin_stock lb  
WHERE i.UPC_CODE IS NOT NULL 
and i.type_code in ('frame','sun') and i.part_no = lb.part_no
and lb.bin_no = 'rr wty'




INSERT INTO CVO_UPC_SCANDATA
SELECT TOP 5 UPC_CODE, GETDATE(), 'RRP2RRR' FROM INV_MASTER i
, lot_bin_stock lb  
WHERE i.UPC_CODE IS NOT NULL 
and i.type_code in ('frame','sun') and i.part_no = lb.part_no
and lb.bin_no = 'rr refurb'

insert into cvo_upc_scandata
select top 5 part_no, getdate(), 'RRP2RRR' from cvo_b2b_xfer_log where issue_no >1376166

update cvo_b2b_xfer_log set date_tran = '05/14/2013' where date_tran is null
select * From cvo_b2b_xfer_log WHERE Date_tran >= '8/5/2013'

*/

CREATE procedure [dbo].[cvo_b2b_xfer_sp] 

as 
-- use cvo
set nocount on

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
id int, part_no varchar(30) not null, qty decimal(20,8) not null,
location varchar(12),from_bin varchar(10),to_bin varchar(10)
)
--


IF NOT EXISTS (SELECT 1 FROM cvo_upc_scandata)
begin 
insert into cvo_b2b_xfer_log
select null, '', '', '', '', '', getdate(), 0, 'tdcsql','NO Data', ' No Scans to process. ', 0,getdate()
return 
end

IF (SELECT OBJECT_ID('tempdb..#scandata')) IS NOT NULL 
BEGIN  drop TABLE #scandata END

select id, upc_code, [datetime] scandate, fct
into #scandata From cvo_upc_scandata

--select id, upc_code, [datetime] scandate, fct, 1 qty
--into #scandata From cvo_upc_scandata_processed p
--where not exists(select 1 from cvo_b2b_xfer_log c inner join inv_master i
--on c.part_no = i.part_no where i.upc_code = p.upc_code)

--select * from #scandata order by id

insert into cvo_upc_scandata_processed
select
 id, upc_code, [datetime], fct, getdate() procdatetime
 from cvo_upc_scandata

delete from cvo_upc_scandata

-- start validation and processing

declare @id int, @valid int, @scan varchar(20), @fct varchar(60)
declare @location varchar(10),  @from_bin varchar(10), @to_bin varchar(10)

select @location = '001', @from_bin = 'RR REFURB', @TO_BIN = 'RR PUTAWAY'


select @id = min(s.id) from #scandata s

while @id is not null
begin
	
	select @scan = s.upc_code, @fct = s.fct from #scandata s where @id = s.id
	
	if (@fct = 'RRR2RRP')
		BEGIN
		select @location = '001', @from_bin = 'RR REFURB', @TO_BIN = 'RR PUTAWAY'
		END	
	if (@fct = 'RRP2RRR')
		BEGIN
		select @location = '001', @from_bin = 'RR PUTAWAY', @TO_BIN = 'RR REFURB'
		END	
	if (@fct = 'RRW2RRP')
		BEGIN
		select @location = '001', @from_bin = 'RR WTY', @TO_BIN = 'RR PUTAWAY'
		END
	-- check to see if the part or upc code exists
	set @valid = 1
	if not exists (select 1 from inv_master where upc_code = @scan ) and  
	   not exists (select 1 from inv_master where part_no = @scan) 
	begin 
		insert into cvo_b2b_xfer_log
		select @id, @location, upc_code, '', @from_bin, @to_bin, scandate, 0, 
		'tdcsql','InvalidUPC', ' Upc code or part number not found. ', 0, getdate()
		from #scandata where id = @id
	    set @valid = 0
	end

	if @valid = 1
	insert into #temp_part_list
		select @id, i.part_no, 1 , @location, @from_bin, @to_bin from inv_master i (nolock) 
		where i.upc_code = @scan
		union all
		select @id, i.part_no, 1 , @location, @from_bin, @to_bin from inv_master i (nolock) 
		where i.part_no = @scan 
	
	-- check that the part is in the from bin

	if (not exists 
		(select 1 from lot_bin_stock lb, #temp_part_list t 
		where lb.part_no = t.part_no and lb.location = t.location
		and lb.bin_no = t.from_bin and t.id = @id) )
		begin 
		-- try to get from rr wty
		if (not exists
			(select 1 from lot_bin_stock lb, #temp_part_list t 
		    where lb.part_no = t.part_no and lb.location = t.location
		    and lb.bin_no = 'RR WTY' and t.id = @id) )
        BEGIN
		 insert into cvo_b2b_xfer_log
		 select id, @location, upc_code, '', @from_bin, @to_bin, scandate, 0, 
			   'tdcsql','InvalidBin', 'Scanned item not in from bin/location. ', 0, getdate()
	    	from #scandata where id = @id
		delete from #temp_part_list where id = @id
		END
		ELSE
		UPDATE #TEMP_PART_LIST SET FROM_BIN = 'RR WTY' WHERE ID = @ID
		
		end
		
	select @id = min(s.id) from #scandata s where s.id > @id
end


--select * From #scandata
--select * from #temp_part_list

-- summarize the list of scans so there is one per part 

IF (SELECT OBJECT_ID('tempdb..#t1')) IS NOT NULL 
BEGIN  drop TABLE #t1 END

select max(id) id, part_no, sum(qty) qty, location , from_bin, to_bin
into #t1
from #temp_part_list
group by part_no, location, from_bin, to_bin
ORDER BY max(ID)

truncate table #temp_part_list

insert into #temp_part_list select * from #t1

-- insert into #temp_part_list values('BCALBBLALS135','1','W03B-07-02','W02E-04-02')
--select * from #temp_part_list

-- process the transactions

declare @part_no varchar(30)
declare @qty decimal(20,0),
		@bin_qty decimal(20,0)

--declare @from_bin varchar(10)
--declare @to_bin varchar(10)
--declare @id int, @location varchar(12)

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
		select @id, @location, @part_no, '', @from_bin, @to_bin, getdate(), @qty, 'tdcsql','BinQTY', 
	'Not enough stock. Only '+ convert(varchar(10),@bin_qty) +' transferred.', 0, getdate()
		select @qty = @bin_qty
	end
	truncate table #adm_bin_xfer
	INSERT INTO #adm_bin_xfer 
	(issue_no, location, part_no, lot_ser, bin_from, bin_to, date_expires, qty, who_entered, reason_code, err_msg)
	values (NULL,@location,@part_no,'1',@from_bin,@to_bin,convert(varchar(12),
		dateadd(yy,1,getdate()),109),@qty,'tdcsql',NULL,NULL)
	begin transaction
		exec tdc_bin_xfer
	commit transaction

	insert into cvo_b2b_xfer_log select *,getdate() date_tran from #adm_bin_xfer 
	-- where issue_no = null -- errors only

	select @id = min(id) from #temp_part_list where id > @id
end

GO
GRANT EXECUTE ON  [dbo].[cvo_b2b_xfer_sp] TO [public]
GO

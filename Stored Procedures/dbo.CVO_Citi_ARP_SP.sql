SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- drop procedure cvo_citi_arp_sp

CREATE procedure [dbo].[CVO_Citi_ARP_SP] @FromDate datetime, @ToDate datetime

as
begin

 

	--ARP - Positive Pay Services - CitiBank
		
	--Usage: 
	-- exec cvo_citi_arp_sp '3/1/2013', '3/8/2013'

	--declare @fromdate datetime, @todate datetime
	--set @fromdate = '3/1/2013'
	--set @todate = '3/31/2013'

	declare @jfromdate int, @jtodate int, 
			@numchecks varchar(10), @totalDollars varchar(10),
			@account_number varchar(10), @bank_number varchar(3)

	select @jfromdate = dbo.adm_get_pltdate_f(@fromdate)
	select @jtodate = dbo.adm_get_pltdate_f(@todate)
	
	select @account_number = '9933121999'
	select @bank_number = '001' -- New York Metro
	 
	IF (SELECT OBJECT_ID('tempdb..#appyhdr')) IS NOT NULL 
	BEGIN DROP TABLE #appyhdr END


	create table #appyhdr
	(
	void varchar(1),
	checknumber varchar(10),
	checkamount float,
	issuedate varchar(8),
	payeeinfo varchar(80)
	)

	insert into #appyhdr
	select 
	case when void_flag = 1 then 'V' else ' ' end as Void, -- pos 22 - len 1
	RIGHT('0000000000'+LTRIM(RTRIM(doc_ctrl_num)),10) as checknumber,
	amt_net as checkamount,
	convert(varchar(8), dateadd(d,date_doc-711858,'1/1/1950'), 112) as IssueDate,
	cast(vendor_code + '-' + payee_name as varchar(80)) as PayeeInfo
	from appyhdr (nolock)
	where date_doc between @jFromDate and @jToDate
	and payment_code = 'CHECK' and amt_net <> 0
	and isnumeric(doc_ctrl_num)=1	
	
	--select @@rowcount

	select @numchecks = right('0000000000'+ltrim(rtrim(str(@@rowcount, 10,0))), 10)
	--select @numchecks

	select @totaldollars = right('0000000000'+ltrim(rtrim(str((select sum(checkamount)*100 from #appyhdr),10,0))), 10)
	--select @totaldollars

	if (@numchecks <> 0)
	begin
	
	-- Build the File

	IF (SELECT OBJECT_ID('tempdb..#arp')) IS NOT NULL 
	BEGIN DROP TABLE #arp END


	create table ##ARP
	(
	id int identity,
	ARP_Record varchar(160)
	)

	insert into ##arp
	select 
	'H'+
	LEFT('CLEARVISION OPTICAL'+SPACE(30),30)+
	CONVERT(VARCHAR(8),GETDATE(),112)+
	SPACE(41)

	insert into ##arp
	select 
	'D' +
	@bank_number+
	@account_number+
	space(7)+
	#appyhdr.void+
	#appyhdr.checknumber+ 
	RIGHT('0000000000'+LTRIM(RTRIM(STR(#appyhdr.checkamount*100,10,0))),10) +
	#appyhdr.issuedate+
	space(15)+
	space(15)+
	#appyhdr.payeeinfo
	from #appyhdr (NOLOCK)

	insert into ##arp
	select
	'T'+
	@bank_number+
	@account_number+
	space(8)+
	@numchecks+
	@totaldollars+
	space(38)

	select arp_record from ##arp order by id

	declare @FILENAME 	VARCHAR(200),
	@BCPCOMMAND VARCHAR(2000),
	@FILENAME_sub VARCHAR(100)

	SET NOCOUNT ON
	set @FILENAME_sub = 'cvo_citi_arp_'+convert(varchar(10),getdate(),112)+'.txt'
	SET @FILENAME = '\\cvo-fs-01\Public_data\Accounting\Accounts Payable\Citi_ARP\' + @FILENAME_sub
	--SET @FILENAME = '\\cvo-fs-01\Public_Data\' + @FILENAME_sub
	--SET @FILENAME = 
	--'\\cvo-fs-01\Public_Data\Accounts Receivable\Buying Groups\Epicor_BGData\'+ @FILENAME_sub
	SET @BCPCOMMAND = 'BCP "select arp_record from cvo..##arp order by id" QUERYOUT "'
	SET @BCPCOMMAND = @BCPCOMMAND + @FILENAME + '" -T -c'

	-- select @bcpcommand

	EXEC MASTER..XP_CMDSHELL @BCPCOMMAND

	drop table ##ARP

	end -- create file
	
end
GO
GRANT EXECUTE ON  [dbo].[CVO_Citi_ARP_SP] TO [public]
GO

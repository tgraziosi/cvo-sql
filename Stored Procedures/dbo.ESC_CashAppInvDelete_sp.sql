SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[ESC_CashAppInvDelete_sp] @ParRecID varchar(40), @Seq int,@ApplyManual smallint
as

-- Rev 3 BNM 8/17/2012 updated to resolve issue 781, Manual cash application
-- 08/21/2012 BNM - resolve issue 781, Manual cash application, add ApplyManual parameter

declare @DocType varchar(3), @PytNum varchar(16)
declare @ErrLog smallint

select @ErrLog = 
		case value_str
			when 'Y' then 1
			else 0
		end
from config
where flag = 'CVOCASHAPP'

Select @ErrLog =  isnull(@ErrLog,0)

if @ErrLog = 1
begin 

	-- Insert the Audit record.
	insert into ESC_CashAppAudit
	select 
		getdate(),								-- ProcessDate		datetime,
		'',										-- UserName		varchar(30),
		@ParRecID,								-- ParentRecID		varchar(40),
		'ESC_CashAppInvDelete_sp',				-- ProcessHdr		varchar(40),
		10,										-- ProcessStepID	int,
		'Remove Transaction Details',			-- ProcessStepName		varchar(40),
		@ParRecID +': '+ convert(varchar, @Seq),-- ProcessValue	varchar(100),
		''										-- ProcessResult	varchar(100)
end

select	@DocType = DocType
from	ESC_CashAppDet
where	ParentRecID = @ParRecID and SeqID = @Seq


if @DocType = 'INV'
begin

if @ErrLog = 1
begin 

	-- Insert the Audit record.
	insert into ESC_CashAppAudit
	select 
		getdate(),								-- ProcessDate		datetime,
		'',										-- UserName		varchar(30),
		@ParRecID,								-- ParentRecID		varchar(40),
		'ESC_CashAppInvDelete_sp',				-- ProcessHdr		varchar(40),
		20,										-- ProcessStepID	int,
		'Document Type',						-- ProcessStepName		varchar(40),
		@DocType,								-- ProcessValue	varchar(100),
		'Document type identified'				-- ProcessResult	varchar(100)
end

	-- If the line is an invoice line then we need to find all the payments that were applied and update them.
	-- Then we need to just delete all the details associated with that line

	insert #ManualCredits(ParentRecID, SeqID)	-- 08/24/2012 BNM - resolve issue 781, Manual cash application, add Manual Credits when unapplied
	select ESC_CashAppDet.ParentRecID, ESC_CashAppDet.SeqID 
	from ESC_CashAppDet 
	join ESC_CashAppInvDet on ESC_CashAppInvDet.ParentRecID = ESC_CashAppDet.ParentRecID and ESC_CashAppInvDet.PytTrx = ESC_CashAppDet.TrxNum
	where	ESC_CashAppInvDet.ParentRecID = @ParRecID and ESC_CashAppInvDet.SeqID = @Seq

	delete	ESC_CashAppInvDet
	where	ParentRecID = @ParRecID and SeqID = @Seq




end

if @DocType = 'PYT'
begin

	select @PytNum = TrxNum from ESC_CashAppDet
	where  ParentRecID = @ParRecID and SeqID = @Seq

	if @ErrLog = 1
	begin 
		
		-- Insert the Audit record.
		insert into ESC_CashAppAudit
		select 
			getdate(),								-- ProcessDate		datetime,
			'',										-- UserName		varchar(30),
			@ParRecID,								-- ParentRecID		varchar(40),
			'ESC_CashAppInvDelete_sp',				-- ProcessHdr		varchar(40),
			20,										-- ProcessStepID	int,
			'Document Type',						-- ProcessStepName		varchar(40),
			@DocType,								-- ProcessValue	varchar(100),
			'Document type identified'				-- ProcessResult	varchar(100)
	end
	
	delete	ESC_CashAppInvDet
	where	ParentRecID = @ParRecID 
	and		PytTrx = @PytNum 
	and		ApplyType = 1


	if @ApplyManual = 1		-- 08/21/2012 BNM - resolve issue 781, Manual cash application, remove manual credits when checkbox cleared
		delete #ManualCredits 
		where  ParentRecID = @ParRecID and SeqID = @Seq 
--		and exists(select 1 from ESC_CashAppDet 
--					where ESC_CashAppDet.ParentRecID = ManualCredits.ParentRecID and ESC_CashAppDet.SeqID = ManualCredits.SeqID
--					and DocBal + AmtApplied between -0.001 and 0.001)



	if @ErrLog = 1
	begin 

		insert into ESC_CashAppAudit
		select 
			getdate(),								-- ProcessDate		datetime,
			'',										-- UserName		varchar(30),
			@ParRecID,								-- ParentRecID		varchar(40),
			'ESC_CashAppInvDelete_sp',				-- ProcessHdr		varchar(40),
			30,										-- ProcessStepID	int,
			'Document Type',						-- ProcessStepName		varchar(40),
			@DocType,								-- ProcessValue	varchar(100),
			'Records deleted'						-- ProcessResult	varchar(100)

	end
		
end

exec ESC_UpdateTotals_sp @ParRecID



GO
GRANT EXECUTE ON  [dbo].[ESC_CashAppInvDelete_sp] TO [public]
GO

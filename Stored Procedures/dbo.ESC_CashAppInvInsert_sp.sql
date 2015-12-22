SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[ESC_CashAppInvInsert_sp] @ParRecID varchar(40), @Seq int,@ApplyCredits smallint,@ApplyManual smallint
as

-- Rev 2 GEP 5/9/2012 updated to apply trx to oldest first.
-- Rev 3 BNM 8/17/2012 updated to resolve issue 781, Manual cash application

declare @DocBal float, @DocType varchar(3), @DocAmtPrev float, @DocTrx varchar(16), @DocNum varchar(16),@CustCode varchar(8)
declare @NetInvBal dec(20,2), @IMinDate int, @PMinDate int
declare @ErrLog smallint

select @ErrLog = 
		case value_str
			when 'Y' then 1
			else 0
		end
from config
where flag = 'CVOCASHAPP'

Select @ErrLog =  isnull(@ErrLog,0)

-- First determine if the user selected an Invoice or a Credit 
select	@DocType = DocType,
		@DocBal = DocBal,
		@DocAmtPrev = AmtApplied,
		@DocTrx	= TrxNum,
		@DocNum	= DocNum,
		@CustCode = CustCode
from	ESC_CashAppDet
where	ParentRecID = @ParRecID
and		SeqID = @Seq



if @DocType = 'PYT' and @DocBal + @DocAmtPrev >= 0
return 

if @DocType = 'INV' and @DocBal + @DocAmtPrev <= 0
return 

declare	@Inv varchar(16), @Trx varchar(16), @InvSeq int, @InvBal float, @PytBal float,@AmtPrevApp float
declare	@ManAmtApplied float, @CreditBal float, @PytChkBal float, @PytCrmBal float	-- 08/21/2012 BNM - resolve issue 781, Manual cash application, track remaining balances separately
declare	@PytDoc varchar(16), @PytTrx varchar(16), @PytSeq int

select @ManAmtApplied = 0		-- 08/21/2012 BNM - resolve issue 781, Manual cash application, track amount of manual credits applied

--************** Payment Selected  *******************************************************************************

if @DocType = 'PYT' 
begin
--1
	-- If we are applying a payment we need to find the invoices to apply it to till its all gone

	declare @PytAmt dec(20,2)
	select @PytAmt = @DocBal + @DocAmtPrev 

	if @PytAmt >= 0 
	return

	if @ErrLog = 1
	begin 

		insert into ESC_CashAppAudit
		select 
			getdate(),										-- ProcessDate		datetime,
			'',												-- UserName		varchar(30),
			@ParRecID,										-- ParentRecID		varchar(40),
			'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
			10,												-- ProcessStepID	int,
			'Entering Payment Processing',					-- ProcessStepName		varchar(40),
			@ParRecID +': '+ convert(varchar, @Seq),		-- ProcessValue	varchar(100),
			'Payment Amt: '+ convert(varchar,@PytAmt)		-- ProcessResult	varchar(100)
	
		insert into ESC_CashAppAudit
		select 
			getdate(),										-- ProcessDate		datetime,
			'',												-- UserName		varchar(30),
			@ParRecID,										-- ParentRecID		varchar(40),
			'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
			15,												-- ProcessStepID	int,
			'Entering Payment Processing',					-- ProcessStepName		varchar(40),
			@DocNum+ ': '+ convert(varchar,@PytAmt),		-- ProcessValue	varchar(100),
			'Payment to be applied'							-- ProcessResult	varchar(100)
	end
	
	-- Get the list of invoices that are open oldest first.
	while @PytAmt < 0
	begin 
	--2
		select	@InvSeq = 0, @IMinDate = 0 

		if @ApplyManual = 1		-- 08/22/2012 BNM - resolve issue 781, Manual cash application, applly credit to partially paid invoices first
		begin
			select	@IMinDate = isnull(min(DocDue),0)
			from	ESC_CashAppDet
			where	DocType = 'INV' and IncludeInPyt = 1
			and		convert(dec(20,2),DocBal - abs(AmtApplied)) > 0
			and		ParentRecID = @ParRecID		

			select	@InvSeq = isnull(min(SeqID),0) 
			from	ESC_CashAppDet
			where	DocType = 'INV' and IncludeInPyt = 1
			and		convert(dec(20,2),DocBal - abs(AmtApplied)) > 0
			and		DocDue = @IMinDate  --Rev 2
			and		ParentRecID = @ParRecID		
		end
		else
		begin
			select	@IMinDate = isnull(min(DocDue),0)
			from	ESC_CashAppDet
			where	DocType = 'INV'
			and		convert(dec(20,2),DocBal - abs(AmtApplied)) > 0
			and		ParentRecID = @ParRecID		

			select	@InvSeq = isnull(min(SeqID),0) 
			from	ESC_CashAppDet
			where	DocType = 'INV'
			and		convert(dec(20,2),DocBal - abs(AmtApplied)) > 0
			and		DocDue = @IMinDate  --Rev 2
			and		ParentRecID = @ParRecID		
		end

/*
		select	@InvSeq = isnull(min(SeqID),0)
		from	ESC_CashAppDet
		where	DocType = 'INV'
		and		cast((DocBal + AmtApplied) as dec(20,2)) > 0.001	-- AmtApplied should be negative
		and		ParentRecID = @ParRecID		
*/


		if @ErrLog = 1
		begin 

			insert into ESC_CashAppAudit
			select 
				getdate(),										-- ProcessDate		datetime,
				'',												-- UserName		varchar(30),
				@ParRecID,										-- ParentRecID		varchar(40),
				'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
				18,												-- ProcessStepID	int,
				'Entering Invoice Processing',					-- ProcessStepName		varchar(40),
				convert(varchar,@InvSeq ),						-- ProcessValue	varchar(100),
				'Invoice to be processed'						-- ProcessResult	varchar(100)
		end
		
		if @InvSeq > 0
		begin
		--3
			-- Get remaining invoice details
			select	@Inv		= DocNum,
					@Trx		= TrxNum,
					@InvBal		= DocBal,
					@AmtPrevApp = AmtApplied  -- this will be negative
			from	ESC_CashAppDet
			where	DocType = 'INV'
			and		SeqID = @InvSeq
			and		ParentRecID = @ParRecID	
			
			select 	@NetInvBal = @InvBal + @AmtPrevApp


			if @ErrLog = 1
			begin 
			
				-- Insert detail record into audit table
				insert into ESC_CashAppAudit
				select 
					getdate(),													-- ProcessDate		datetime,
					'',															-- UserName		varchar(30),
					@ParRecID,													-- ParentRecID		varchar(40),
					'ESC_CashAppInvInsert_sp',									-- ProcessHdr		varchar(40),
					20,															-- ProcessStepID	int,
					'Processing Invoice',										-- ProcessStepName		varchar(40),
					@Trx+ '-BAL: '+convert(varchar,@NetInvBal),					-- ProcessValue	varchar(100),
					'Invoice Found with net balance'								-- ProcessResult	varchar(100)
			end			
	
				if abs(@PytAmt) >= (@NetInvBal)	--Net Balance
				begin
				--4a
					-- If Payment exceeds the invoice balance then use the invoice balance.
					insert into ESC_CashAppInvDet
					select 
						@ParRecID,
						@InvSeq,
						@DocTrx,		
						@DocNum,
						( @NetInvBal * -1),
						@Inv,
						1

						-- Update the payment record balance to reflect what has been applied.
						update	ESC_CashAppDet
						set		AmtApplied = AmtApplied + @NetInvBal,
								IncludeInPyt = 1
						where	ParentRecID = @ParRecID
						and		TrxNum = @DocTrx
						and		DocType = 'PYT'

						-- Update the invoice record balance to reflect what has been applied.
						update	ESC_CashAppDet
						set		AmtApplied = AmtApplied - @NetInvBal ,
								IncludeInPyt = 1
						where	ParentRecID = @ParRecID
						and		DocType = 'INV'
						and		SeqID = @InvSeq

					if @ErrLog = 1
					begin 
				
						-- Insert audit record.
						insert into ESC_CashAppAudit
						select 
							getdate(),											-- ProcessDate		datetime,
							'',													-- UserName		varchar(30),
							@ParRecID,											-- ParentRecID		varchar(40),
							'ESC_CashAppInvInsert_sp',							-- ProcessHdr		varchar(40),
							30,													-- ProcessStepID	int,
							'Processing Invoice',								-- ProcessStepName		varchar(40),
							convert(varchar,( @NetInvBal * -1 )),				-- ProcessValue	varchar(100),
							'Invoice Amount Applied'							-- ProcessResult	varchar(100)

						insert into ESC_CashAppAudit
						select 
							getdate(),										-- ProcessDate		datetime,
							'',												-- UserName		varchar(30),
							@ParRecID,										-- ParentRecID		varchar(40),
							'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
							32,												-- ProcessStepID	int,
							'Processing Invoice',							-- ProcessStepName		varchar(40),
							convert(varchar,(AmtApplied) ),					-- ProcessValue	varchar(100),
							'Updated inv amt applied'						-- ProcessResult	varchar(100)
						from ESC_CashAppDet
						where	ParentRecID = @ParRecID
						and		DocNum		= @Inv
						and		DocType		= 'INV'
					end

					-- Update the payment to reflect what has been applied.
					select @PytAmt = @PytAmt + @NetInvBal
					select @ManAmtApplied = @ManAmtApplied + @NetInvBal		-- 08/22/2012 BNM - resolve issue 781, Manual cash application, calculate manual credits applied
					select @NetInvBal = 0

					if @ErrLog = 1
					begin 

						insert into ESC_CashAppAudit
						select 
							getdate(),										-- ProcessDate		datetime,
							'',												-- UserName		varchar(30),
							@ParRecID,										-- ParentRecID		varchar(40),
							'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
							33,												-- ProcessStepID	int,
							'Processing Invoice',							-- ProcessStepName		varchar(40),
							convert(varchar,(@PytAmt) ),					-- ProcessValue	varchar(100),
							'Payment remaining to apply'					-- ProcessResult	varchar(100)


						insert into ESC_CashAppAudit
						select 
							getdate(),										-- ProcessDate		datetime,
							'',												-- UserName		varchar(30),
							@ParRecID,										-- ParentRecID		varchar(40),
							'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
							35,												-- ProcessStepID	int,
							'Processing Invoice',							-- ProcessStepName		varchar(40),
							convert(varchar,(DocBal+AmtApplied) ),					-- ProcessValue	varchar(100),
							'Calculated Invoice Balance'					-- ProcessResult	varchar(100)
						from    ESC_CashAppDet
						where	ParentRecID = @ParRecID
						and		DocType = 'INV'
						and		SeqID = @InvSeq

					end

					select	@InvSeq = isnull(min(SeqID),0)
					from	ESC_CashAppDet
					where	DocType = 'INV'
					and		cast((DocBal + AmtApplied) as dec(20,2)) > 0.001	-- AmtApplied should be negative
					and		ParentRecID = @ParRecID		

					if @ErrLog = 1
					begin 

						insert into ESC_CashAppAudit
						select 
							getdate(),										-- ProcessDate		datetime,
							'',												-- UserName		varchar(30),
							@ParRecID,										-- ParentRecID		varchar(40),
							'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
							36,												-- ProcessStepID	int,
							'Invoice Processing',							-- ProcessStepName		varchar(40),
							convert(varchar,@InvSeq ),						-- ProcessValue	varchar(100),
							'Next Invoice to be processed'					-- ProcessResult	varchar(100)

					end
				--4a
				end	
				else
				begin
				--4b
					-- If Payment is less than the invoice balance then use the payment balance.

					if @ErrLog = 1
					begin 

						-- Insert audit record.
						insert into ESC_CashAppAudit
						select 
							getdate(),											-- ProcessDate		datetime,
							'',													-- UserName		varchar(30),
							@ParRecID,											-- ParentRecID		varchar(40),
							'ESC_CashAppInvInsert_sp',							-- ProcessHdr		varchar(40),
							41,													-- ProcessStepID	int,
							'Processing Invoice',								-- ProcessStepName		varchar(40),
							convert(varchar,@PytAmt),							-- ProcessValue	varchar(100),
							'Payment Amount < Invoice Balance+Amt Applied'		-- ProcessResult	varchar(100)


						insert into ESC_CashAppInvDet
						select 
							@ParRecID,
							@InvSeq,
							@DocTrx,		
							@DocNum,
							@PytAmt,
							@Inv,
							1
					end
					
						-- select @PytAmt
					
					-- Update the payment record balance to reflect what has been applied.
					update	ESC_CashAppDet
					set		AmtApplied = AmtApplied - @PytAmt
					where	ParentRecID = @ParRecID
					and		TrxNum = @DocTrx
					and		DocType = 'PYT'

					-- Update the invoice record balance to reflect what has been applied.
					update	ESC_CashAppDet
					set		AmtApplied = AmtApplied + @PytAmt
					where	ParentRecID = @ParRecID
					and		TrxNum = @Trx
					and		DocType = 'INV'
					and		SeqID   = @InvSeq

					if @ErrLog = 1
					begin 
						insert into ESC_CashAppAudit
						select 
							getdate(),										-- ProcessDate		datetime,
							'',												-- UserName		varchar(30),
							@ParRecID,										-- ParentRecID		varchar(40),
							'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
							42,												-- ProcessStepID	int,
							'Processing Invoice',							-- ProcessStepName		varchar(40),
							convert(varchar,(AmtApplied) ),					-- ProcessValue	varchar(100),
							'Updated inv amt applied'						-- ProcessResult	varchar(100)
						from ESC_CashAppDet
						where	ParentRecID = @ParRecID
						and		TrxNum = @DocTrx
						and		DocType = 'INV'
						and		SeqID   = @InvSeq
					end
						
					select @ManAmtApplied = @ManAmtApplied + @PytAmt		-- 08/22/2012 BNM - resolve issue 781, Manual cash application, calculate manual credits applied
					select @PytAmt = 0	


					if @ErrLog = 1
					begin 
						-- Insert audit record.
						insert into ESC_CashAppAudit
						select 
							getdate(),								-- ProcessDate		datetime,
							'',										-- UserName		varchar(30),
							@ParRecID,								-- ParentRecID		varchar(40),
							'ESC_CashAppInvInsert_sp',				-- ProcessHdr		varchar(40),
							43,										-- ProcessStepID	int,
							'Processing Invoice',					-- ProcessStepName		varchar(40),
							convert(varchar,@PytAmt),				-- ProcessValue	varchar(100),
							'Payment Amount Remaining'				-- ProcessResult	varchar(100)
					end
					
				--4b 
				end				
			--3
			end		
			else
			begin
				Break
			end
			

		if @PytAmt >= 0
			Break
		else
			Continue

	-- 2
	end

	if @ErrLog = 1
	begin 

		-- Insert audit record.
		insert into ESC_CashAppAudit
		select 
			getdate(),								-- ProcessDate		datetime,
			'',										-- UserName		varchar(30),
			@ParRecID,								-- ParentRecID		varchar(40),
			'ESC_CashAppInvInsert_sp',				-- ProcessHdr		varchar(40),
			50,										-- ProcessStepID	int,
			'Processing Payment',					-- ProcessStepName		varchar(40),
			'',										-- ProcessValue	varchar(100),
			'Done Applying Payment'					-- ProcessResult	varchar(100)
	end
--1				
end


--***************************************************************************************
--****************************** Invoice Document ***************************************

if @DocType = 'INV'
begin

	if @ErrLog = 1
	begin 

		insert into ESC_CashAppAudit
		select 
			getdate(),								-- ProcessDate		datetime,
			'',										-- UserName		varchar(30),
			@ParRecID,								-- ParentRecID		varchar(40),
			'ESC_CashAppInvInsert_sp',				-- ProcessHdr		varchar(40),
			100,										-- ProcessStepID	int,
			'Entering Invoice Processing',			-- ProcessStepName		varchar(40),
			@ParRecID +': '+ convert(varchar, @Seq),-- ProcessValue	varchar(100),
			''										-- ProcessResult	varchar(100)
	end

	-- If we are absorbing payments to invoices we need to track the invoice balance and find the oldest
	-- payment to apply then apply it and get the next oldest payment and apply that until the invoice
	-- is 0.

	-- Get the initial invoice balance
	select @InvBal = @DocBal + @DocAmtPrev 

	if @ErrLog = 1
	begin 

		insert into ESC_CashAppAudit
		select 
			getdate(),										-- ProcessDate		datetime,
			'',												-- UserName		varchar(30),
			@ParRecID,										-- ParentRecID		varchar(40),
			'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
			105,											-- ProcessStepID	int,
			'Get Invoice Balance',							-- ProcessStepName		varchar(40),
			convert(varchar, @InvBal),						-- ProcessValue	varchar(100),
			''												-- ProcessResult	varchar(100)
	end
	
	-- If the invoice balance is < 0 exit the procedure
	if @InvBal <= 0 
	return


	-- Loop through the payments oldest payment first.
	while @InvBal > 0 
	begin 

		select	@Trx = NULL
		
		if @ApplyCredits = 1
		begin
			-- Get the oldest credit that has a balance left to apply

			select	@PMinDate = isnull(min(DocDue),0)
			from	ESC_CashAppDet
			where	DocType = 'PYT'
			and		DocBal + AmtApplied < - 0.001		-- GEP 11/3/2011 was < 0
			and		ParentRecID = @ParRecID

			select	@PytSeq = min(SeqID) 
			from	ESC_CashAppDet
			where	DocType = 'PYT'
			and		DocBal + AmtApplied < - 0.001		-- GEP 11/3/2011 was < 0
			and		ParentRecID = @ParRecID
			and		DocDue = @PMinDate

			
/*
			select	min(SeqID) 
			from	ESC_CashAppDet
			where	DocType = 'PYT'
			and		DocBal + AmtApplied < 0
			and		ParentRecID = '013748'
*/

			if @ErrLog = 1
			begin 
					
				-- Insert the Audit record.
				insert into ESC_CashAppAudit
				select 
					getdate(),											-- ProcessDate		datetime,
					'',													-- UserName		varchar(30),
					@ParRecID,											-- ParentRecID		varchar(40),
					'ESC_CashAppInvInsert_sp',							-- ProcessHdr		varchar(40),
					110,												-- ProcessStepID	int,
					'Getting Next Payment',								-- ProcessStepName		varchar(40),
					'Payment Seq ID: '+convert(varchar, @PytSeq),		-- ProcessValue	varchar(100),
					'Payment found'										-- ProcessResult	varchar(100)
			end
		
		end

-- begin - 08/17/2012 BNM - resolve issue 781, Manual cash application
		if @ApplyManual = 1 and (select RemCrmBal from ESC_CashAppHdr where ParentRecID = @ParRecID) > 0.001
		begin
			-- Get the credit that has been checked to apply

			select	@PMinDate = isnull(min(DocDue),0)
			from	ESC_CashAppDet
			where	DocType = 'PYT'
			and		IncludeInPyt = 1
			and		DocBal + AmtApplied < - 0.001
			and		ParentRecID = @ParRecID

			select	@PytSeq = min(SeqID) 
			from	ESC_CashAppDet
			where	DocType = 'PYT'
			and		IncludeInPyt = 1
			and		DocBal + AmtApplied < - 0.001
			and		ParentRecID = @ParRecID
			and		DocDue = @PMinDate

			
			if @ErrLog = 1
			begin 
					
				-- Insert the Audit record.
				insert into ESC_CashAppAudit
				select 
					getdate(),											-- ProcessDate		datetime,
					'',													-- UserName		varchar(30),
					@ParRecID,											-- ParentRecID		varchar(40),
					'ESC_CashAppInvInsert_sp',							-- ProcessHdr		varchar(40),
					110,												-- ProcessStepID	int,
					'Getting Manually Applied Payment',								-- ProcessStepName		varchar(40),
					'Payment Seq ID: '+convert(varchar, @PytSeq),		-- ProcessValue	varchar(100),
					'Payment found'										-- ProcessResult	varchar(100)
			end
		
		end
-- end - 08/17/2012 BNM - resolve issue 781, Manual cash application

		-- If the sequence id is not null procede otherwise skip this section
		if 	@PytSeq is not null
		begin 

			select @AmtPrevApp = 0

			-- Get the remaining payment info
			select	@PytDoc		= DocNum,
					@Trx		= TrxNum,
					@PytBal		= DocBal,
					@AmtPrevApp = AmtApplied,
					@CreditBal	= DocBal + AmtApplied
			from	ESC_CashAppDet
			where	DocType = 'PYT'
			and		ParentRecID = @ParRecID		-- GEP 11/3/2011 pulling wrong transaction data without ParRecID
			and		SeqID = @PytSeq

			if @ErrLog = 1
			begin 

				-- Insert Audit Record
				insert into ESC_CashAppAudit
				select 
					getdate(),												-- ProcessDate		datetime,
					'',														-- UserName		varchar(30),
					@ParRecID,												-- ParentRecID		varchar(40),
					'ESC_CashAppInvInsert_sp',								-- ProcessHdr		varchar(40),
					120,													-- ProcessStepID	int,
					'Applying Payment',										-- ProcessStepName		varchar(40),
					'INV:'+ convert(varchar,@InvBal) + ' / '+
					'PYT:'+ convert(varchar,(@PytBal+ @AmtPrevApp)) ,		-- ProcessValue	varchar(100),
					''														-- ProcessResult	varchar(100)
			end
			
			-- Insert the detail record.
			insert into ESC_CashAppInvDet
			select 
				@ParRecID,
				@Seq,
				@Trx,		
				@PytDoc,
				case
					when @InvBal > abs(@PytBal+ @AmtPrevApp) then (@PytBal+ @AmtPrevApp)
					when @InvBal <=  abs(@PytBal+ @AmtPrevApp) then (@InvBal * -1)
				end,	
				@DocNum,
				1


			select @InvBal,@PytBal,@AmtPrevApp
					
			select @ManAmtApplied = @ManAmtApplied +		-- 08/22/2012 BNM - resolve issue 781, Manual cash application, calculate manual credits applied
				case
					when @InvBal > abs(@PytBal+ @AmtPrevApp) then abs(@PytBal+ @AmtPrevApp)
					when @InvBal <=  abs(@PytBal+ @AmtPrevApp) then @InvBal
				end,
					@CreditBal = @CreditBal + 
				case
					when @InvBal > abs(@PytBal+ @AmtPrevApp) then abs(@PytBal+ @AmtPrevApp)
					when @InvBal <=  abs(@PytBal+ @AmtPrevApp) then @InvBal
				end

-- begin - 08/30/2012 BNM - resolve issue 781, Manual cash application, update remaining balance and remove manual credits
			if @ApplyManual = 1	
			begin
				-- Update the remaining credit balance for the payment including this manually applied credit
				update	ESC_CashAppHdr
				set		RemBalance = RemBalance - 
					case
						when @InvBal > abs(@PytBal+ @AmtPrevApp) then abs(@PytBal+ @AmtPrevApp)
						when @InvBal <=  abs(@PytBal+ @AmtPrevApp) then @InvBal
					end,
						RemCrmBal = RemCrmBal - 
					case
						when @InvBal > abs(@PytBal+ @AmtPrevApp) then abs(@PytBal+ @AmtPrevApp)
						when @InvBal <=  abs(@PytBal+ @AmtPrevApp) then @InvBal
					end
				where	ParentRecID = @ParRecID

				if @CreditBal between -0.001 and 0.001	-- 08/21/2012 BNM - resolve issue 781, Manual cash application, remove manual credits when checkbox cleared
				begin
					delete #ManualCredits where  ParentRecID = @ParRecID and SeqID = @PytSeq
					set @PytSeq = NULL
				end
			end
-- end - 08/30/2012 BNM - resolve issue 781, Manual cash application

			-- Now update the payment to reflect the amount applied to invoice.
			update	ESC_CashAppDet
			set		AmtApplied = AmtApplied +
				case
					when @InvBal > abs(@PytBal+ @AmtPrevApp) then abs(@PytBal+ @AmtPrevApp)
					when @InvBal <=  abs(@PytBal+ @AmtPrevApp) then @InvBal
				end
			where	ParentRecID = @ParRecID
			and		TrxNum = @Trx
			and		DocType = 'PYT'


			-- Now update the invoice to reflect the payment amount applied.
			update	ESC_CashAppDet
			set		AmtApplied = AmtApplied - 
				case
					when @InvBal > abs(@PytBal+ @AmtPrevApp) then abs(@PytBal+ @AmtPrevApp)
					when @InvBal <=  abs(@PytBal+ @AmtPrevApp) then (@InvBal)
				end
			where	ParentRecID = @ParRecID
			and		SeqID =  @Seq
			and		DocType = 'INV'


			if @ErrLog = 1
			begin 

				insert into ESC_CashAppAudit
				select 
					getdate(),											-- ProcessDate		datetime,
					'',													-- UserName		varchar(30),
					@ParRecID,											-- ParentRecID		varchar(40),
					'ESC_CashAppInvInsert_sp',							-- ProcessHdr		varchar(40),
					130,												-- ProcessStepID	int,
					'Payment Application',								-- ProcessStepName		varchar(40),
					TrxNum +': '+convert(varchar, AmtApplied),			-- ProcessValue	varchar(100),
					'Total payment amount applied to date'				-- ProcessResult	varchar(100)
				from	ESC_CashAppDet
				where	ParentRecID = @ParRecID
				and		TrxNum = @Trx
				and		DocType = 'PYT'


				insert into ESC_CashAppAudit
				select 
					getdate(),											-- ProcessDate		datetime,
					'',													-- UserName		varchar(30),
					@ParRecID,											-- ParentRecID		varchar(40),
					'ESC_CashAppInvInsert_sp',							-- ProcessHdr		varchar(40),
					131,												-- ProcessStepID	int,
					'Payment Application',								-- ProcessStepName		varchar(40),
					DocNum +': '+convert(varchar, AmtApplied),			-- ProcessValue	varchar(100),
					'Payment amount absorbed to invoice'				-- ProcessResult	varchar(100)
				from	ESC_CashAppDet
				where	ParentRecID = @ParRecID
				and		SeqID =  @Seq
				and		DocType = 'INV'

			end

			-- Update the invoice balance to reflect the amount applied to the invoice	

			select @InvBal = @InvBal -
				case
					when @InvBal > abs(@PytBal+ @AmtPrevApp) then abs(@PytBal+ @AmtPrevApp)
					when @InvBal <=  abs(@PytBal+ @AmtPrevApp) then (@InvBal)
				end

			if @ErrLog = 1
			begin 

				insert into ESC_CashAppAudit
				select 
					getdate(),											-- ProcessDate		datetime,
					'',													-- UserName		varchar(30),
					@ParRecID,											-- ParentRecID		varchar(40),
					'ESC_CashAppInvInsert_sp',							-- ProcessHdr		varchar(40),
					135,												-- ProcessStepID	int,
					'Payment Application',								-- ProcessStepName		varchar(40),
					@DocNum +': '+convert(varchar, @InvBal),				-- ProcessValue	varchar(100),
					'Invoice Balance'									-- ProcessResult	varchar(100)
			end
		end		
		else
		begin
		-- If there are no more credits then the system will attempt to apply the manual payment.
			
			select	@PytDoc		= CheckNum,
					@PytSeq		= 0,
					@PytBal		= RemBalance,
					@PytChkBal	= RemChkBal,	-- 08/21/2012 BNM - resolve issue 781, Manual cash application, track remaining balances separately
					@PytCrmBal	= RemCrmBal,
					@AmtPrevApp = 0
			from 	ESC_CashAppHdr
			where	ParentRecID = @ParRecID			

			if @ApplyManual = 1 and @PytChkBal > 0	-- 08/17/2012 BNM - resolve issue 781, do not attempt to apply remaining balance if no more credits available
					set @PytBal = @PytChkBal
			else	break

			if @PytBal > 0 
			begin 

				if @ErrLog = 1
				begin 

					insert into ESC_CashAppAudit
					select 
						getdate(),								-- ProcessDate		datetime,
						'',										-- UserName		varchar(30),
						@ParRecID,								-- ParentRecID		varchar(40),
						'ESC_CashAppInvInsert_sp',				-- ProcessHdr		varchar(40),
						51,										-- ProcessStepID	int,
						'Applying Manual Payment',				-- ProcessStepName		varchar(40),
						'INV:'+ convert(varchar,@InvBal) + ' / '+
						'PYT:'+ convert(varchar,@PytBal) ,		-- ProcessValue	varchar(100),
						'Inv balance > Pyt balance'				-- ProcessResult	varchar(100)
				end

				insert into ESC_CashAppInvDet
				select 
					@ParRecID,
					@Seq,
					'',		
					@PytDoc,
					case 
						when @InvBal >= @PytBal then (@PytBal * -1)
						when @InvBal < @PytBal then (@InvBal * -1)
					end,	
					@DocNum,
					2


				-- Update the invoice with the payment detail
				update	ESC_CashAppDet
				set		AmtApplied = AmtApplied - 
					case 
						when @InvBal >= @PytBal then (@PytBal)
						when @InvBal < @PytBal then (@InvBal)
					end
				where	ParentRecID = @ParRecID
				and		SeqID = @Seq
				and		DocType = 'INV'
				

				-- Update the remaining balance for the payment
				update	ESC_CashAppHdr
				set		RemBalance = RemBalance - 
					case 
						when @InvBal >= @PytBal then (@PytBal)
						when @InvBal < @PytBal then (@InvBal)
					end,
						RemChkBal = RemChkBal -		-- 08/21/2012 BNM - resolve issue 781, Manual cash application, track remaining balances separately
					case 
						when @InvBal >= @PytBal then (@PytBal)
						when @InvBal < @PytBal then (@InvBal)
					end
				where	ParentRecID = @ParRecID
			
			end			
			
			if 1 = 1
				BREAK
			else
				CONTINUE

		end

		if @InvBal <= 0 
			Break
		else
			Continue
	end

	if @ErrLog = 1
	begin 

		insert into ESC_CashAppAudit
		select 
			getdate(),								-- ProcessDate		datetime,
			'',										-- UserName		varchar(30),
			@ParRecID,								-- ParentRecID		varchar(40),
			'ESC_CashAppInvInsert_sp',				-- ProcessHdr		varchar(40),
			160,									-- ProcessStepID	int,
			'Invoice Application Complete',			-- ProcessStepName		varchar(40),
			'' ,									-- ProcessValue	varchar(100),
			''										-- ProcessResult	varchar(100)
	end
				
end

-- begin - 08/17/2012 BNM - resolve issue 781, Manual cash application
if @ApplyManual = 1 
begin
	update ESC_CashAppDet
	set IncludeInPyt = 
		case 
			when @DocType = 'INV' and AmtApplied = 0 then 0
			else	1
		end
	where	ParentRecID = @ParRecID
	and		SeqID = @Seq

	if @DocType = 'PYT' 
	begin
		insert #ManualCredits(ParentRecID, SeqID) 
		select ParentRecID, SeqID	from ESC_CashAppDet
		where	ParentRecID = @ParRecID
		and		SeqID = @Seq
		and		IncludeInPyt = 1
		and		DocBal + AmtApplied < - 0.001

		if @ErrLog = 1
		begin 

			insert into ESC_CashAppAudit
			select 
				getdate(),										-- ProcessDate		datetime,
				'',												-- UserName		varchar(30),
				@ParRecID,										-- ParentRecID		varchar(40),
				'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
				170,											-- ProcessStepID	int,
				'Updating Remaining Balance',					-- ProcessStepName		varchar(40),
				@ParRecID +': '+ convert(varchar, @Seq),		-- ProcessValue	varchar(100),
				'Manual Payment Amt: '+ convert(varchar,@DocBal)-- ProcessResult	varchar(100)
	
			insert into ESC_CashAppAudit
			select 
				getdate(),										-- ProcessDate		datetime,
				'',												-- UserName		varchar(30),
				@ParRecID,										-- ParentRecID		varchar(40),
				'ESC_CashAppInvInsert_sp',						-- ProcessHdr		varchar(40),
				171,											-- ProcessStepID	int,
				'Updating Remaining Balance',					-- ProcessStepName		varchar(40),
				@ParRecID +': '+ convert(varchar, @Seq),		-- ProcessValue	varchar(100),
				'Applied Amt: '+ convert(varchar,@ManAmtApplied)-- ProcessResult	varchar(100)
		end

		-- Update the remaining balance for the payment including this manually applied credit
		update	ESC_CashAppHdr
		set		RemBalance = RemBalance + ABS(@DocBal + @ManAmtApplied),
				RemCrmBal = RemCrmBal + ABS(@DocBal + @ManAmtApplied)
		where	ParentRecID = @ParRecID
	end
end
else
-- end - 08/17/2012 BNM - resolve issue 781, Manual cash application
	update ESC_CashAppDet
	set IncludeInPyt = 
		case 
			when AmtApplied = 0 then 0
			else	1
		end
	where	ParentRecID = @ParRecID
	
	


GO
GRANT EXECUTE ON  [dbo].[ESC_CashAppInvInsert_sp] TO [public]
GO

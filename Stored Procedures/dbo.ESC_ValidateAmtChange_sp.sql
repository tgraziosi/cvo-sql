SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure	[dbo].[ESC_ValidateAmtChange_sp] 
@ParRec varchar(40),@Doc varchar(16), @Amt float, @Inv varchar(16), @PytType smallint, @PrevAmt float,
@NewAmt float OUTPUT, @ErrMsgOut varchar(255)	OUTPUT, @ErrFlag smallint OUTPUT
as

declare @PytBal float,  @InvBal float

-- Get the invoice balance
select	@InvBal = DocBal 
from	ESC_CashAppDet 
where	DocNum = @Inv
and		Doctype = 'INV'
and		ParentRecID = @ParRec

-- select @InvBal
-- get the amount applied to the invoice excluding the payment we are trying to apply.
select	@InvBal = @InvBal + isnull(sum(PytApp),0)
from	ESC_CashAppInvDet 
where	InvDoc = @Inv
and		ParentRecID = @ParRec
and		PytDoc != @Doc


-- select @ParRec, @Inv, @Doc, @Amt, @PytType, @PrevAmt

-- If we get past the part above then we have a valid document, trx and apply type. 
-- Next figure out the true balance of the payment against all other invoices except the one we are working with.
select @PytBal = dbo.fn_ESC_GetPytBal( @ParRec, @Inv, @Doc, @PytType )

-- select @Amt,@PytBal

if (abs(@Amt) <= abs(@PrevAmt) and abs(@Amt) <= @InvBal)
begin
	select	@NewAmt = abs(@Amt)*-1,
			@ErrFlag = 1,
			@ErrMsgOut = 'Payment entered is less than the previous amount.'

	return 

end

-- Check if amount entered exceeds available PYT balance. If it does reset the amount to the remaining balance and exit.
if abs(@Amt) > abs(@PytBal)
begin

	select	@NewAmt = abs(@PytBal)*-1,
			@ErrFlag = -2,
			@ErrMsgOut = 'Payment amount entered exceeds available Pyt balance. Resetting to available Pyt balance.'

	-- Now make sure the amount does not exceed the invoice balance
	if abs(@NewAmt) > abs(@InvBal)
	begin	
		select	@NewAmt = abs(@InvBal)*-1,
				@ErrFlag = -2,
				@ErrMsgOut = 'Payment amount entered exceeds the invoice balance. Resetting to available invoice balance.'
	end

			
	return 

end

if abs(@Amt) <= abs(@PytBal)
begin


	-- If amount entered <= available balance, then use the amount entered and exit
	select	@NewAmt = abs(@Amt)*-1,
			@ErrFlag = 1,
			@ErrMsgOut = 'Payment amount valid for available balance and will be applied.'


-- 	select @NewAmt, @InvBal
	
	-- If amount entered <= available balance, then use the amount entered and exit
	if abs(@NewAmt) > abs(@InvBal)
	begin	
		select	@NewAmt = abs(@InvBal)*-1,
				@ErrFlag = -2,
				@ErrMsgOut = 'Payment amount entered exceeds the invoice balance. Resetting to available invoice balance.'
	end
			
	return 

end


/*
-- If Payment amount exceeds invoice balance reset the payment amount to the invoice balance.
if abs(@Amt) <= abs(@PytBal)
begin

	select	@NewAmt = abs(@Amt)*-1,
			@ErrFlag = 1,
			@ErrMsgOut = 'Payment amount valid for available balance and will be applied.'
			
	return 

end
*/


GO
GRANT EXECUTE ON  [dbo].[ESC_ValidateAmtChange_sp] TO [public]
GO

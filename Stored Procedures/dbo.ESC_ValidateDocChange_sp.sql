SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure	[dbo].[ESC_ValidateDocChange_sp] 
@ParRec varchar(40),@Doc varchar(16), @Inv varchar(16), @PytType smallint,
@NewDoc varchar(16) OUTPUT, @NewTrx varchar(16) OUTPUT,@NewAppType smallint OUTPUT, @ErrMsgOut varchar(255)	OUTPUT, @ErrFlag smallint OUTPUT
as

declare @ValPytDoc varchar(16)


-- first figure out if the document is valid. If not exit and update the fields 
-- first look in the Detail table for credit instrument.
select	@ValPytDoc = isnull(DocNum,''),
		@NewAppType = 1,
		@NewTrx = TrxNum
from	ESC_CashAppDet (NOLOCK)
where	DocNum = @Doc
and		ParentRecID = @ParRec
and		DocType = 'PYT'


-- if the document is not found look for it in the header table
if isnull(@ValPytDoc,'') = ''
begin
	select	@ValPytDoc = CheckNum,
			@NewAppType = 2,
			@NewTrx = ''
	from	ESC_CashAppHdr (NOLOCK)
	where	CheckNum = @Doc
	and		ParentRecID = @ParRec
end


-- If the document supplied could not be found then set the values to blanks and exit the procedure.
if isnull(@ValPytDoc,'') = ''
begin
	select	@NewDoc = '',
			@NewTrx = '',
			@NewAppType = 0,
			@ErrFlag = -1,
			@ErrMsgOut = 'Document '+ @Doc +' not found!'
			
	return 

end

-- If the Trx Number could not be found then set the values to blanks and exit the procedure.
if @NewTrx = '' and @NewAppType = 1
begin
	select	@NewDoc = '',
			@NewTrx = '',
			@NewAppType = 0,
			@ErrFlag = -1,
			@ErrMsgOut = 'Trx Number for payment '+ @Doc +' not found!'
			
	return 

end


-- select @ValPytDoc, @ParRec,@Inv

-- select * from ESC_CashAppInvDet
/*
-- If the Doc Number already exists on the Invocie then set the values to blanks and exit the procedure.
if exists(select 1 from ESC_CashAppInvDet where  PytDoc = @ValPytDoc and ParentRecID = @ParRec and InvDoc = @Inv)
begin
	select	@NewDoc = '',
			@NewTrx = '',
			@NewAppType = 0,
			@ErrFlag = -1,
			@ErrMsgOut = 'Payment '+ @Doc +' has already been assigned to this invoice! You must update the existing record!'
			
	return 

end
*/

-- If the Doc Number is found and the ApplyTYpe is 0 then set the values to blanks and exit the procedure.
if @NewDoc != '' and @NewAppType = 0
begin
	select	@NewDoc = '',
			@NewTrx = '',
			@NewAppType = 0,
			@ErrFlag = -1,
			@ErrMsgOut = 'Apply Type not valid for payment '+ @Doc 
			
	return 

end

select	@NewDoc = @ValPytDoc,
		@ErrFlag = 1,
		@ErrMsgOut = 'Passed validation'


GO
GRANT EXECUTE ON  [dbo].[ESC_ValidateDocChange_sp] TO [public]
GO

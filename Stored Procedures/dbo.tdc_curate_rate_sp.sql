SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_curate_rate_sp] 
AS
 
DECLARE @curr_key varchar(8),
	@rate_type_home varchar(8),
	@rate_type_oper varchar(8),
	@juldate int,
	@po varchar(16)

SELECT @po = MIN(po_no) FROM #receipts 

SELECT @curr_key = curr_key, @rate_type_home = rate_type_home, @rate_type_oper = rate_type_oper
  FROM purchase (nolock) 
 WHERE po_no = @po

SELECT @juldate = DATEDIFF(D, '1901-01-01', getdate()) + 693961
EXEC dbo.fs_curate_sp @juldate, @curr_key, @rate_type_home, @rate_type_oper

RETURN 100
GO
GRANT EXECUTE ON  [dbo].[tdc_curate_rate_sp] TO [public]
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[icv_fs_trans_wrap] @transtype char(3), @cc_number varchar(20), @ccexpmo char(2), @ccexpyr char(4),
		 @ordtotal decimal(20,8), @order_no int, @ext int AS
BEGIN
DECLARE @response varchar(60)
EXEC icv_fs_trans @transtype, @cc_number, @ccexpmo, @ccexpyr, @ordtotal, @response OUT, @order_no, @ext
SELECT @response
END

GO
GRANT EXECUTE ON  [dbo].[icv_fs_trans_wrap] TO [public]
GO

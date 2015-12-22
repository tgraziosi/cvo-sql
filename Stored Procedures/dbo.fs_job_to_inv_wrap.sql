SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[fs_job_to_inv_wrap] @prodno int, @partno varchar(30), 
	@qty decimal(20,8), @who varchar(10), @lot varchar(25), @bin varchar(12), @edt datetime AS

begin

DECLARE @err int

EXEC dbo.fs_job_to_inv @prodno, @partno, @qty, @who, @lot, @bin, @edt, @err OUT

SELECT @err 'err'

END 
GO
GRANT EXECUTE ON  [dbo].[fs_job_to_inv_wrap] TO [public]
GO

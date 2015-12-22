SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARGetNumberBlock_SP] @process_group_num varchar( 16 ),
 @debug_level smallint = 0
AS

DECLARE @result int,
 @tran_started smallint,
 @sequence_key int,
 @masked varchar( 35 ),
 @mask varchar( 35 ),
 @maskp varchar( 35 ),
 @maskheader varchar( 35 ),
 @maskcontent varchar( 35 ),
 @maskchar char,
 @maskzero int,
 @maskmid int,
 @maskflag int,
 @maskpl int,
 @num int,
 @snum int,
 @num2031 int,
 @num2032 int,
 @num_type int,
 @zeros int,
 @pounds int,
 @masklength int,
 @cur_num int,
 @trunc_table smallint,
 @cnt int

BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argnb.sp" + ", line " + STR( 69, 5 ) + " -- ENTRY: "

 select @cnt = count(*) from #arnumblk

 

 SELECT @num = count(*)
 FROM #arnumblk
 WHERE get_num = 1

 
 SET rowcount 1

 SELECT @num_type = num_type
 FROM #arnumblk

 SET rowcount 0

 
 SELECT @mask = RTRIM(mask)
 FROM ewnumber
 WHERE num_type = @num_type

 
 SELECT @maskflag = SIGN(CHARINDEX("0", @mask)) + SIGN(CHARINDEX("#", @mask))

 
 IF @maskflag = 1
 BEGIN

 
 SELECT @maskzero = SIGN(CHARINDEX("0", @mask))
 IF @maskzero = 1
 SELECT @maskchar = "0"
 ELSE
 SELECT @maskchar = "#"

 
 SELECT @maskp = REVERSE(@mask)

 SELECT @maskpl = DATALENGTH(@maskp)

 WHILE SUBSTRING(@maskp, 1, 1) = @maskchar
 BEGIN
 SELECT @maskp = SUBSTRING(@maskp, 2, @maskpl - 1)

 SELECT @maskpl = DATALENGTH(@maskp)

 END

 SELECT @maskheader = REVERSE(@maskp),
 @maskcontent = SUBSTRING(@mask, @maskpl + 1, DATALENGTH(@mask)-@maskpl)
 END


 
 CREATE TABLE #arnumblk_id
 (
 char16_ref1 varchar(16) NULL,
 char8_ref1 varchar(8) NULL,
 smallint_ref1 smallint NULL,
 sequence_key numeric identity
 )



 
 IF( @@trancount = 0)
 BEGIN
 SELECT @tran_started = 1
 BEGIN TRANSACTION
 END

 
 UPDATE ewnumber
 SET fill1 = ' '
 WHERE num_type = @num_type

 
 SELECT @snum = next_num
 FROM ewnumber
 WHERE num_type = @num_type

 
 UPDATE ewnumber
 SET next_num = next_num + @num
 WHERE num_type = @num_type

 IF ( @tran_started = 1 )
 COMMIT TRANSACTION


 
 INSERT INTO #arnumblk_id
 (
 char16_ref1, char8_ref1, smallint_ref1
 )
 SELECT char16_ref1, char8_ref1, smallint_ref1
 FROM #arnumblk
 WHERE get_num = 1


 IF @maskflag = 1
 BEGIN


 
 UPDATE #arnumblk
 SET masked = @maskheader +
 ISNULL(substring( @maskcontent, 1 * @maskzero, datalength(@maskcontent) -
 datalength(ltrim(str(#arnumblk_id.sequence_key + @snum - 1)))),"") +
 ltrim(str(#arnumblk_id.sequence_key + @snum - 1)),
 get_num = 2,
 sequence_key = #arnumblk_id.sequence_key,
 num = #arnumblk_id.sequence_key + @snum - 1
 FROM #arnumblk_id
 WHERE #arnumblk.char16_ref1 = #arnumblk_id.char16_ref1
 AND #arnumblk.char8_ref1 = #arnumblk_id.char8_ref1
 AND #arnumblk.smallint_ref1 = #arnumblk_id.smallint_ref1

 END
 ELSE
 BEGIN

 

 UPDATE #arnumblk
 SET sequence_key = #arnumblk_id.sequence_key,
 num = #arnumblk_id.sequence_key + @snum - 1
 FROM #arnumblk_id
 WHERE #arnumblk.char16_ref1 = #arnumblk_id.char16_ref1
 AND #arnumblk.char8_ref1 = #arnumblk_id.char8_ref1
 AND #arnumblk.smallint_ref1 = #arnumblk_id.smallint_ref1

 SELECT @sequence_key = 1

 WHILE( 1=1 )
 BEGIN

 SELECT @num = num
 FROM #arnumblk
 WHERE @sequence_key = sequence_key 
 AND num_type = @num_type

 IF( @@rowcount = 0 )
 BREAK

 EXEC fmtctlnm_sp @num,
 @mask,
 @masked output,
 @result output

 UPDATE #arnumblk
 SET masked = @masked,
 get_num = 2
 WHERE @sequence_key = sequence_key

 SELECT @sequence_key = @sequence_key + 1

 END
 END

 DROP table #arnumblk_id

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argnb.sp" + ", line " + STR( 274, 5 ) + " -- EXIT: "
 RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARGetNumberBlock_SP] TO [public]
GO

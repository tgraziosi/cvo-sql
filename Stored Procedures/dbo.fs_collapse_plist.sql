SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_collapse_plist] @pno int, @pext int  AS 
BEGIN

declare @needqty decimal(20,8), @pqty decimal(20,8)
declare @exseq varchar(4), @seq varchar(4), @cs char(1)
declare @ptype char(1),    @stat char(1),   @loc varchar(10)
declare @expart varchar(30), @part varchar(30)
declare @lno int, @next_lno int, @pline int, @start_lno int
declare @rcnt int, @cnt int, @lp int
declare @msg varchar(255)
CREATE table #tempdel (
line_no int,
constrain char(1) NULL )
select @lno=isnull( (select min(line_no) from prod_list 
                     where part_type='-'), 0)
while @lno > 0 begin
   INSERT #tempdel
   SELECT line_no, constrain
   FROM   prod_list
   WHERE  p_line=@lno
   UPDATE #tempdel set constrain='Z' where line_no=@lno
   select @lno=isnull( (select min(line_no) from prod_list 
                        where part_type='-' and line_no>@lno), 0)
end
select @lno=isnull( (select min(line_no) from #tempdel 
                     where constrain='C'), 0)
while @lno > 0 begin
   INSERT #tempdel
   SELECT line_no, constrain
   FROM   prod_list
   WHERE  p_line=@lno
   UPDATE #tempdel set constrain='Z' where line_no=@lno
   select @lno=isnull( (select min(line_no) from prod_list 
                        where constrain='C' and line_no>@lno), 0)
end
DELETE prod_list from #tempdel
where prod_no=@pno and prod_ext=@pext and prod_list.line_no=#tempdel.line_no
UPDATE prod_list set part_type='M'
where prod_no=@pno and prod_ext=@pext and part_type='-'
END
GO
GRANT EXECUTE ON  [dbo].[fs_collapse_plist] TO [public]
GO

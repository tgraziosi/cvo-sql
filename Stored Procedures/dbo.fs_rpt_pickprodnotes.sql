SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_pickprodnotes] @pno int, @pext int, @lno int  AS 
BEGIN
 declare @x int, @y int, @parent int
 declare @asmpart varchar(30), @comppart varchar(30), @note1 varchar(255)
 CREATE TABLE #tpick (
 prod_no int, 
 prod_ext int, 
 line_no int, 
 seq_no char(4), 
 part_no varchar(30), 
	 location	 varchar(10), 
 p_note varchar(255) NULL, 
 p_note2 varchar(255) NULL, 
 p_note3 varchar(255) NULL, 
 p_note4 varchar(255) NULL, 
 p_line int NULL 
)
 INSERT #tpick (
 prod_no , 
 prod_ext , 
 line_no , 
 seq_no , 
 part_no , 
	 location ,
 p_note , 
 p_note2 , 
 p_note3 , 
 p_note4 , 
 p_line )
 SELECT dbo.prod_list.prod_no ,
 dbo.prod_list.prod_ext ,
 dbo.prod_list.line_no ,
 dbo.prod_list.seq_no ,
 dbo.prod_list.part_no ,
 dbo.prod_list.location ,
 dbo.prod_list.note ,
 '' ,
 '' ,
 '' ,
 dbo.prod_list.p_line 
 FROM dbo.prod_list 
 WHERE dbo.prod_list.prod_no = @pno AND 
 dbo.prod_list.prod_ext = @pext AND 
 dbo.prod_list.line_no = @lno 

 update #tpick set p_note='' where p_note is null
 select @note1=isnull( (select p_note from #tpick
 where #tpick.prod_no = @pno AND 
 #tpick.prod_ext = @pext AND 
 #tpick.line_no = @lno), '' )

 if @note1 > '' begin
 select prod_no , 
 prod_ext , 
 line_no , 
 seq_no , 
 part_no , 
 p_note , 
 p_note2 , 
 p_note3 , 
 p_note4 , 
 p_line 
 from #tpick
 return
 end

 SELECT @parent=isnull( (select p_line from #tpick
 where #tpick.prod_no = @pno AND 
 #tpick.prod_ext = @pext AND 
 #tpick.line_no = @lno and p_line <> line_no), 0 )				-- mls 3/16/04 SCR 32536
 
 if @parent > 0 begin
 select @asmpart=isnull( (select part_no from dbo.prod_list 
 where dbo.prod_list.prod_no = @pno AND 
 dbo.prod_list.prod_ext = @pext AND 

 dbo.prod_list.line_no = @parent), '' ) 
 end
 else begin
 select @asmpart=isnull( (select part_no from dbo.produce_all
 where dbo.produce_all.prod_no = @pno AND 
 dbo.produce_all.prod_ext = @pext), '' )
 end
 if @asmpart > '' begin
 UPDATE #tpick set p_note = CASE WHEN w.note is null THEN '' ELSE w.note END,
 p_note2 = CASE WHEN w.note2 is null THEN '' ELSE w.note2 END,
 p_note3 = CASE WHEN w.note3 is null THEN '' ELSE w.note3 END,
 p_note4 = CASE WHEN w.note4 is null THEN '' ELSE w.note4 END
 FROM what_part w, #tpick p
 WHERE w.asm_no=@asmpart and w.seq_no=p.seq_no and w.part_no=p.part_no and 
	 ( w.location = p.location OR w.location = 'ALL' )

 UPDATE #tpick set p_note = CASE WHEN w.note is null THEN '' ELSE w.note END,	-- mls 3/16/04 SCR 32536
 p_note2 = CASE WHEN w.note2 is null THEN '' ELSE w.note2 END,
 p_note3 = CASE WHEN w.note3 is null THEN '' ELSE w.note3 END,
 p_note4 = CASE WHEN w.note4 is null THEN '' ELSE w.note4 END
 FROM what_part w, #tpick p, resource_group r
 WHERE w.asm_no=@asmpart and w.seq_no=p.seq_no and w.part_no=r.group_part_no and 
	r.resource_part_no = p.part_no and
	 ( w.location = p.location OR w.location = 'ALL' )

 end
 select prod_no , 
 prod_ext , 
 line_no , 
 seq_no , 
 part_no , 
 p_note , 
 p_note2 , 
 p_note3 , 
 p_note4 , 
 p_line 
 from #tpick
 
END

GO
GRANT EXECUTE ON  [dbo].[fs_rpt_pickprodnotes] TO [public]
GO

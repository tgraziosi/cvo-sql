SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_bomnotes] @process_ctrl_num varchar(30), @range varchar(8000) as


BEGIN
if @process_ctrl_num != ''
begin
declare @part_no varchar(30)
select @part_no = registry_data from registry (nolock) 
  where registry_name = @process_ctrl_num and registry_type = 'R'

if isnull(@part_no,'') = ''
  select @part_no = @process_ctrl_num

exec ('  SELECT what_part.asm_no,   
         what_part.part_no,   
         what_part.uom,   
         what_part.who_entered,   
         what_part.seq_no,   
         what_part.attrib,   
         what_part.active,   
         what_part.bench_stock,   
         what_part.note,   
         what_part.eff_date,   
         what_part.date_entered,   
         inv_master.description,   
         what_part.conv_factor,   
         what_part.constrain,   
         what_part.fixed,   
         what_part.qty,   
         what_part.alt_seq_no,   
         what_part.note2,   
         what_part.note3,   
         what_part.note4,
	 convert(text,what_part.note + note2 + note3 + note4)
    FROM what_part,   
         inv_master  
   WHERE ( what_part.asm_no = inv_master.part_no ) and  
(isnull(what_part.note,'''')  != '''' or
 isnull(what_part.note2,'''') != '''' or
 isnull(what_part.note3,'''') != '''' or
 isnull(what_part.note4,'''') != '''') and asm_no = ''' + @part_no + '''')

delete registry
where registry_name = @process_ctrl_num and registry_type = 'R'

exec  pctrlupd_sp @process_ctrl_num, 3
end
else
begin
select @range = replace(@range,'"','''')
exec ('  SELECT what_part.asm_no,   
         what_part.part_no,   
         what_part.uom,   
         what_part.who_entered,   
         what_part.seq_no,   
         what_part.attrib,   
         what_part.active,   
         what_part.bench_stock,   
         what_part.note,   
         what_part.eff_date,   
         what_part.date_entered,   
         inv_master.description,   
         what_part.conv_factor,   
         what_part.constrain,   
         what_part.fixed,   
         what_part.qty,   
         what_part.alt_seq_no,   
         what_part.note2,   
         what_part.note3,   
         what_part.note4,
	 convert(text,what_part.note + note2 + note3 + note4)
    FROM what_part,   
         inv_master  
   WHERE ( what_part.asm_no = inv_master.part_no ) and  
(isnull(what_part.note,'''')  != '''' or
 isnull(what_part.note2,'''') != '''' or
 isnull(what_part.note3,'''') != '''' or
 isnull(what_part.note4,'''') != '''') and ' + @range)
end
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_bomnotes] TO [public]
GO

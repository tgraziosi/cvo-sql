SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_jobperf] @prodno int, @estno int, 
                                    @loc varchar(10), @stat char(1), 
                                    @bdate datetime, @edate datetime AS

declare @minstat char(1), @maxstat char(1)
declare @xlp int, @eno int, @pno int
declare @schqty decimal(20,8), @estqty decimal(20,8)
declare @mcost1 decimal(20,8), @dcost1 decimal(20,8)
declare @ocost1 decimal(20,8), @ucost1 decimal(20,8)
declare @mcost2 decimal(20,8), @dcost2 decimal(20,8)
declare @ocost2 decimal(20,8), @ucost2 decimal(20,8)
declare @mmulti decimal(20,8)              
declare @dmulti decimal(20,8)               
declare @omulti decimal(20,8)               
declare @umulti decimal(20,8)            

select @minstat = 'N'
select @maxstat = 'T'
if @stat = 'O' begin
   select @maxstat = 'Q'
end
if @stat = 'S' begin
   select @minstat = 'R'
end
CREATE table #job (
   location          varchar(10),
   status            char(1),
   prod_no           int,
   prod_ext          int,
   prod_date         datetime,
   prod_qty          decimal(20,8),
   est_no            int NULL,
   description       varchar(255) NULL,
   est_price         decimal(20,8),
   est_matl_dolrs    decimal(20,8),
   est_labr_dolrs    decimal(20,8),
   est_labr2_dolrs   decimal(20,8),
   est_labr3_dolrs   decimal(20,8),
   plan_matl_dolrs   decimal(20,8),
   plan_labr_dolrs   decimal(20,8),
   plan_labr2_dolrs  decimal(20,8),
   plan_labr3_dolrs  decimal(20,8),
   act_matl_dolrs    decimal(20,8),
   act_labr_dolrs    decimal(20,8),
   act_labr2_dolrs   decimal(20,8),
   act_labr3_dolrs   decimal(20,8),
   act_matl_std      decimal(20,8),
   act_labr_std      decimal(20,8),
   act_labr2_std     decimal(20,8),
   act_labr3_std     decimal(20,8),
   row_id            int identity(1,1)
)
insert #job (
       location,        prod_no,         prod_ext,         prod_date,	prod_qty,
       status,          est_no,          description,      est_price,
       est_matl_dolrs,  est_labr_dolrs,  est_labr2_dolrs,  est_labr3_dolrs, 
       plan_matl_dolrs, plan_labr_dolrs, plan_labr2_dolrs, plan_labr3_dolrs, 
       act_matl_dolrs,  act_labr_dolrs,  act_labr2_dolrs,  act_labr3_dolrs,
       act_matl_std,    act_labr_std,    act_labr2_std,    act_labr3_std
)
select location, prod_no,      prod_ext,      prod_date,	qty_scheduled,
       status,   est_no,       description,   0,
       0,        0,            0,             0,
       0,        0,            0,             0,
       0,        0,            0,             0,
       0,        0,            0,             0
from produce_all p
where prod_type='J' and
      (@prodno=0 or (@prodno>0 and p.prod_no=@prodno)) and
      (@estno=0 or (@estno>0 and p.est_no=@estno)) and
      location like @loc and 
      (status>=@minstat and status<=@maxstat) and
      (prod_date>=@bdate and prod_date<=@edate)
select @xlp=isnull( (select min(row_id) from #job),0)
while @xlp > 0 begin
   select @eno    = isnull( (select est_no from #job where row_id=@xlp),0)
   select @schqty = isnull( (select prod_qty from #job where row_id=@xlp),0)
   select @pno    = isnull( (select prod_no from #job where row_id=@xlp),0)
   if @eno > 0 begin
      select @estqty = isnull( (select MAX( dbo.estimates.quoted_qty )
	                        from dbo.estimates
   	                        where dbo.estimates.est_no = @eno and 
                                dbo.estimates.quoted_qty <= @schqty), 0)

      select @mmulti = material_multi, @dmulti = direct_multi,
             @omulti = ovhd_multi, @umulti = util_multi
             from estimates 
             where est_no=@eno and quoted_qty=@estqty

      select @mcost1 = sum( matl_cost * qty ), @dcost1 = sum( direct_dolrs * qty ),
             @ocost1 = sum( ovhd_dolrs * qty ), @ucost1 = sum( util_dolrs * qty )
             from est_list 
             where est_no=@eno and quoted_qty=@estqty and fixed='Y'

      select @mcost2 = sum( matl_cost * qty * @schqty), @dcost2 = sum( direct_dolrs * qty * @schqty ),
             @ocost2 = sum( ovhd_dolrs * qty * @schqty ), @ucost2 = sum( util_dolrs * qty * @schqty )
             from est_list  
             where est_no=@eno and quoted_qty=@estqty and fixed='N'

      if @mmulti is null select @mmulti = 1
      if @dmulti is null select @dmulti = 1
      if @omulti is null select @omulti = 1
      if @umulti is null select @umulti = 1

      if @mcost1 is null select @mcost1 = 0
      if @dcost1 is null select @dcost1 = 0
      if @ocost1 is null select @ocost1 = 0
      if @ucost1 is null select @ucost1 = 0

      if @mcost2 is null select @mcost2 = 0
      if @dcost2 is null select @dcost2 = 0
      if @ocost2 is null select @ocost2 = 0
      if @ucost2 is null select @ucost2 = 0

      update #job set est_matl_dolrs=isnull( (select (@mcost1 + @mcost2)),0),
                      est_labr_dolrs=isnull( (select (@dcost1 + @dcost2)),0),
                      est_labr2_dolrs=isnull( (select (@ocost1 + @ocost2)),0),
                      est_labr3_dolrs=isnull( (select (@ucost1 + @ucost2)),0)
                      where est_no=@eno









      update #job set est_price=quoted_price from estimates 
             where #job.est_no=estimates.est_no and #job.est_no=@eno
   end
   if @pno > 0 begin
      select @mcost1 = sum( plan_qty * i.std_cost ),      @dcost1 = sum( plan_qty *i.std_direct_dolrs ),
             @ocost1 = sum( plan_qty *i.std_ovhd_dolrs ), @ucost1 = sum( plan_qty *i.std_util_dolrs ),
             @mcost2 = sum( used_qty * i.std_cost ),      @dcost2 = sum( used_qty *i.std_direct_dolrs ),
             @ocost2 = sum( used_qty *i.std_ovhd_dolrs ), @ucost2 = sum( used_qty *i.std_util_dolrs )
             from prod_list, inv_list i 
             where prod_list.part_no=i.part_no and
                   prod_list.location=i.location and
                   prod_list.prod_no=@pno

      update #job set plan_matl_dolrs=isnull( (select @mcost1),0),
                      plan_labr_dolrs=isnull( (select @dcost1),0),
                      plan_labr2_dolrs=isnull( (select @ocost1),0),
                      plan_labr3_dolrs=isnull( (select @ucost1),0),
                      act_matl_std=isnull( (select @mcost2),0),
                      act_labr_std=isnull( (select @dcost2),0),
                      act_labr2_std=isnull( (select @ocost2),0),
                      act_labr3_std=isnull( (select @ucost2),0)
                      where prod_no=@pno
   end
   select @xlp=isnull( (select min(row_id) from #job where row_id>@xlp),0)
end
select location,        prod_no,         prod_ext,
       status,          est_no,          description,
       est_matl_dolrs,  est_labr_dolrs+est_labr2_dolrs+est_labr3_dolrs,   
       plan_matl_dolrs, plan_labr_dolrs+plan_labr2_dolrs+plan_labr3_dolrs, 

       act_matl_dolrs,  act_labr_dolrs+act_labr2_dolrs+act_labr3_dolrs,
       act_matl_std,    act_labr_std+act_labr2_std+act_labr3_std, 
       est_price, @estqty est_qty,
       @prodno,         @loc,          @stat, 
       @bdate,          @edate
from #job
order by location, prod_date, prod_no, prod_ext
GO
GRANT EXECUTE ON  [dbo].[fs_rpt_jobperf] TO [public]
GO

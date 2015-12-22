SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_qc_analysis] @part_no varchar(30),  @vendor varchar(12), @loc varchar(10),
                 @test1 varchar(10), @min1 varchar(50),    @max1 varchar(50),
                 @test2 varchar(10), @min2 varchar(50),    @max2 varchar(50),
                 @test3 varchar(10), @min3 varchar(50),    @max3 varchar(50),
                 @test4 varchar(10), @min4 varchar(50),    @max4 varchar(50) AS

declare @tno int, @qtype char(1)
select @tno = 4
if @test4 is null begin
   select @test4 = ''
end
if @test3 is null begin
   select @test3 = ''
end
if @test2 is null begin
   select @test2 = ''
end
if @test1 is null begin
   select @test1 = ''
end
if @test4 <= '' begin
   select @tno = 3
end
if @test3 <= '' begin
   select @tno = 2
end
if @test2 <= '' begin
   select @tno = 1
end
Create table #temp1
   ( qc_no int, part_no varchar(30), lot_ser varchar(25) NULL,
     location varchar(10),           vendor varchar(12) NULL,
     result1 varchar(50) NULL,       result2 varchar(50) NULL,
     result3 varchar(50) NULL,       result4 varchar(50) NULL,
     qty decimal(20,8) )
Create table #trpt
   ( qc_no int, part_no varchar(30), lot_ser varchar(25) NULL,
     location varchar(10),           vendor varchar(12) NULL,
     result1 varchar(50) NULL,       result2 varchar(50) NULL,
     result3 varchar(50) NULL,       result4 varchar(50) NULL,
     qty decimal(20,8) ,             description varchar(255) NULL  )




SELECT   @qtype=IsNull( qc_test.test_type,'A')
   FROM  qc_test
   WHERE qc_test.kys=@test1
if @qtype<>'N' begin
   SELECT @qtype='A'
end
if @qtype='N' begin
   INSERT #temp1
      SELECT qc_detail.qc_no,       qc_detail.part_no,
             qc_results.lot_ser,    lot_bin_stock.location,
             qc_results.vendor_key, qc_detail.value,
             null,                  null,
             null,                  lot_bin_stock.qty
      FROM qc_detail, lot_bin_stock
      JOIN qc_results ON lot_bin_stock.lot_ser = qc_results.lot_ser
      WHERE qc_detail.qc_no=qc_results.qc_no AND
            qc_results.location like @loc AND
            qc_results.part_no like @part_no AND
            qc_results.vendor_key like @vendor AND
            qc_detail.test_key=@test1 AND qc_detail.status='S' AND
            qc_detail.value>=@min1 AND qc_detail.value<=@max1           -- slubey 11/17/99 SCR21292
						

              					
      ORDER BY qc_results.lot_ser
end
if @qtype='A' begin
   INSERT #temp1
      SELECT qc_detail.qc_no,       qc_detail.part_no,
             qc_results.lot_ser,    lot_bin_stock.location,
             qc_results.vendor_key, qc_detail.value,
             null,                  null,
             null,                  lot_bin_stock.qty
      FROM qc_detail, lot_bin_stock
      JOIN qc_results ON lot_bin_stock.lot_ser = qc_results.lot_ser
      WHERE qc_detail.qc_no=qc_results.qc_no AND
            qc_results.location like @loc AND
            qc_results.part_no like @part_no AND
            qc_results.vendor_key like @vendor AND
            qc_detail.test_key=@test1 AND qc_detail.status='S' AND
            qc_detail.value>=@min1 AND qc_detail.value<=@max1 	-- slubey 11/17/99 SCR21292
								--qc_detail.value like @min1
      ORDER BY qc_results.lot_ser
end
if @tno = 1 begin
   INSERT #trpt
      SELECT qc_no,           #temp1.part_no, lot_ser,
             #temp1.location, #temp1.vendor,
             result1,         result2,
             result3,         result4,
             qty,             i.description
      FROM  #temp1, inv_master i
      WHERE #temp1.part_no=i.part_no
end



if @tno > 1 begin
   SELECT   @qtype=IsNull( qc_test.test_type,'A')
      FROM  qc_test
      WHERE qc_test.kys=@test2
   if @qtype<>'N' begin
      SELECT @qtype='A'
   end
   Create table #temp2
      ( qc_no int, part_no varchar(30), lot_ser varchar(25) NULL,
        location varchar(10),           vendor varchar(12) NULL,
        result1 varchar(50) NULL,       result2 varchar(50) NULL,
        result3 varchar(50) NULL,       result4 varchar(50) NULL,
        qty decimal(20,8) )

   if @qtype='N' begin
      INSERT #temp2
         SELECT qc_detail.qc_no,    qc_detail.part_no, #temp1.lot_ser,
                #temp1.location,    #temp1.vendor,
                #temp1.result1,     qc_detail.value,
                null,               null,
                qty
         FROM qc_detail
         JOIN #temp1 ON qc_detail.qc_no=#temp1.qc_no
         WHERE qc_detail.test_key=@test2 AND
               qc_detail.value>=@min2 AND qc_detail.value<=@max2 	-- slubey 11/17/99 SCR21292
						

         ORDER BY #temp1.lot_ser
   end
   if @qtype='A' begin
      INSERT #temp2
         SELECT qc_detail.qc_no,    qc_detail.part_no, #temp1.lot_ser,
                #temp1.location,    #temp1.vendor,
                #temp1.result1,     qc_detail.value,
                null,               null,
                qty
         FROM qc_detail
         JOIN #temp1 ON qc_detail.qc_no=#temp1.qc_no
         WHERE qc_detail.test_key=@test2 AND
            qc_detail.value>=@min2 AND qc_detail.value<=@max2 	-- slubey 11/17/99 SCR21292
							        --   qc_detail.value like @min2
         ORDER BY #temp1.lot_ser
   end
end
if @tno = 2 begin
   INSERT #trpt
      SELECT qc_no,           #temp2.part_no,  lot_ser,
             #temp2.location, #temp2.vendor,
             result1,         result2,
             result3,         result4,
             qty,             i.description
      FROM  #temp2, inv_master i
      WHERE #temp2.part_no=i.part_no
end



if @tno > 2 begin
   Drop table #temp1
   Create table #temp3
      ( qc_no int, part_no varchar(30), lot_ser varchar(25) NULL,
        location varchar(10),           vendor varchar(12) NULL,
        result1 varchar(50) NULL,       result2 varchar(50) NULL,
        result3 varchar(50) NULL,       result4 varchar(50) NULL,
        qty decimal(20,8) )

   SELECT   @qtype=IsNull( qc_test.test_type,'A')
      FROM  qc_test
      WHERE qc_test.kys=@test3
   if @qtype<>'N' begin
      SELECT @qtype='A'
   end
   if @qtype='N' begin
      INSERT #temp3
         SELECT qc_detail.qc_no,    qc_detail.part_no, #temp2.lot_ser,
                #temp2.location,    #temp2.vendor,
                #temp2.result1,     #temp2.result2,
                qc_detail.value,    null,
                qty
         FROM qc_detail
         JOIN #temp2 ON qc_detail.qc_no=#temp2.qc_no
         WHERE qc_detail.test_key=@test3 AND
               qc_detail.value>=@min3 AND qc_detail.value<=@max3 	


         ORDER BY #temp2.lot_ser
   end
   if @qtype='A' begin
      INSERT #temp3
         SELECT qc_detail.qc_no,    qc_detail.part_no, #temp2.lot_ser,
                #temp2.location,    #temp2.vendor,
                #temp2.result1,     #temp2.result2,
                qc_detail.value,    null,
                qty

         FROM qc_detail
         JOIN #temp2 ON qc_detail.qc_no=#temp2.qc_no
         WHERE qc_detail.test_key=@test3 AND
               qc_detail.value>=@min3 AND qc_detail.value<=@max3 

         ORDER BY #temp2.lot_ser
   end
end
if @tno = 3 begin
   INSERT #trpt
      SELECT qc_no,           #temp3.part_no, lot_ser,
             #temp3.location, #temp3.vendor,
             result1,         result2,
             result3,         result4,
             qty,             i.description
      FROM  #temp3, inv_master i
      WHERE #temp3.part_no=i.part_no
end



if @tno > 3 begin
   Drop table #temp2
   Create table #temp4
      ( qc_no int, part_no varchar(30), lot_ser varchar(25) NULL,
        location varchar(10),           vendor varchar(12) NULL,
        result1 varchar(50) NULL,       result2 varchar(50) NULL,
        result3 varchar(50) NULL,       result4 varchar(50) NULL,
        qty decimal(20,8) )

   SELECT   @qtype=IsNull( qc_test.test_type,'A')
      FROM  qc_test
      WHERE qc_test.kys=@test4
   if @qtype<>'N' begin
      SELECT @qtype='A'
   end
   if @qtype='N' begin
      INSERT #temp4
         SELECT qc_detail.qc_no,    qc_detail.part_no, #temp3.lot_ser,
                #temp3.location,    #temp3.vendor,
                #temp3.result1,     #temp3.result2,
                #temp3.result3,     qc_detail.value,
                qty
         FROM qc_detail
         JOIN #temp3 ON qc_detail.qc_no=#temp3.qc_no
         WHERE qc_detail.test_key=@test4 AND
               qc_detail.value>=@min4 AND qc_detail.value<=@max4 	


         ORDER BY #temp3.lot_ser
   end
   if @qtype='A' begin
      INSERT #temp4
         SELECT qc_detail.qc_no,    qc_detail.part_no, #temp3.lot_ser,
                #temp3.location,    #temp3.vendor,
                #temp3.result1,     #temp3.result2,
                #temp3.result3,     qc_detail.value,
                qty
         FROM qc_detail
         JOIN #temp3 ON qc_detail.qc_no=#temp3.qc_no
         WHERE qc_detail.test_key=@test4 AND
               qc_detail.value>=@min1 AND qc_detail.value<=@max1 	


         ORDER BY #temp3.lot_ser
   end
end
if @tno = 4 begin
   INSERT #trpt
      SELECT qc_no,           #temp4.part_no, lot_ser,
             #temp4.location, #temp4.vendor,
             result1,         result2,
             result3,         result4,
             qty,             i.description
      FROM #temp4, inv_master i
      WHERE #temp4.part_no=i.part_no
end
SELECT qc_no,         part_no, lot_ser,
       location,      vendor,
       result1,       result2,
       result3,       result4,
       qty,           description
   FROM #trpt
   ORDER BY part_no,location,lot_ser


/**/
GO
GRANT EXECUTE ON  [dbo].[fs_qc_analysis] TO [public]
GO

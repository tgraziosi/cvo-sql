SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_replenish_early_warning_sp] AS 
BEGIN

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @Fill_threshold INT, @group_code VARCHAR(20)

SET @Fill_threshold = 50
SET @group_code = 'PICKAREA'

DECLARE	@email_address		varchar(255),
		@subject			varchar(255),
		@message			varchar(8000),
		@part_no			varchar(30),
		@bin_no				VARCHAR(20),
		@alloc_qty			INT,
		@replen_qty			INT,
		@inv_Qty			INT,
		@rc					INT

IF(OBJECT_ID('dbo.cvo_replenish_early_warning_tbl') is null) 
begin       
	CREATE TABLE cvo_replenish_early_warning_tbl
	( [type_code] varchar(10), 
	[part_no] varchar(30), 
	[location] varchar(10), 
	[bin_no] varchar(12), 
	[replenish_min_lvl] decimal(20,0), 
	[replenish_max_lvl] decimal(20,0), 
	[inv_qty] decimal(38,8), 
	[alloc_qty] decimal(38,8), 
	[alloc_pct] decimal(38,6), 
	[bin_fill_pct] decimal(38,6), 
	[replen_qty] decimal(38,8), 
	[asofdate] DATETIME,
	[Notify_date] DATETIME NULL,
	[Ack_Date] DATETIME NULL,
	[id] INT IDENTITY(1,1) PRIMARY KEY
	)
end

IF(OBJECT_ID('tempdb.dbo.#T') is not null)  drop table #T

SELECT stuck.type_code ,
       stuck.part_no ,
       stuck.location ,
       stuck.bin_no ,
	   stuck.replenish_min_lvl,
       stuck.replenish_max_lvl ,
       stuck.inv_qty ,
       stuck.alloc_qty ,
       stuck.alloc_pct ,
       stuck.bin_fill_pct,
	   stuck.replen_qty,
	   ROW_NUMBER() OVER (ORDER BY part_no, location, bin_no) id
	   INTO #T
	   FROM
(
SELECT i.type_code,
	   tbr.part_no ,
       tbr.location ,
       tbr.bin_no ,
	   tbr.replenish_min_lvl,
       tbr.replenish_max_lvl ,
       inv.qty inv_qty,
       alloc.alloc_qty
, alloc_pct = CASE WHEN ISNULL(inv.qty,0) = 0 THEN 0 ELSE ISNULL(alloc.alloc_qty,0)/inv.qty*100 END
, bin_fill_pct = CASE WHEN ISNULL(tbr.replenish_max_lvl,0) = 0 THEN 0 ELSE ISNULL(inv.qty,0)/tbr.replenish_max_lvl*100 END
, pq.replen_qty

FROM 

-- replen info
(
SELECT tbr.part_no, tbr.location, tbr.bin_no, tbr.replenish_min_lvl, tbr.replenish_max_lvl
FROM dbo.tdc_bin_replenishment tbr
JOIN tdc_bin_master b ON b.location = tbr.location AND b.bin_no = tbr.bin_no
WHERE b.group_code = @group_code
) AS tbr

JOIN inv_master i 
 ON i.part_no = tbr.part_no


LEFT OUTER JOIN 

-- inventory
(SELECT lb.part_no, lb.location, lb.bin_no, SUM(lb.qty) qty
FROM lot_bin_stock lb
JOIN tdc_bin_master b ON b.location = lb.location AND b.bin_no = lb.bin_no
WHERE b.group_code = @group_code
GROUP BY lb.part_no ,
         lb.location ,
         lb.bin_no
		 ) inv ON inv.bin_no = tbr.bin_no AND inv.location = tbr.location AND inv.part_no = tbr.part_no

LEFT OUTER join

-- allocations
(SELECT part_no, location, bin_no, SUM(qty) alloc_qty
FROM dbo.tdc_soft_alloc_tbl AS tsat
WHERE tsat.order_type = 'S'
GROUP BY tsat.part_no ,
         tsat.location ,
         tsat.bin_no
		 ) alloc ON alloc.bin_no = tbr.bin_no AND alloc.location = tbr.location AND alloc.part_no = tbr.part_no

-- open replenishment picks
LEFT OUTER JOIN
( SELECT part_no, location, tpq.next_op, SUM(qty_to_process) replen_qty
	FROM dbo.tdc_pick_queue AS tpq WHERE tpq.trans = 'MGTB2B'
	GROUP BY tpq.part_no ,
             tpq.location ,
             tpq.next_op
	) pq ON pq.next_op = tbr.bin_no AND pq.location = tbr.location AND pq.part_no = tbr.part_no

) stuck
WHERE alloc_pct > @Fill_threshold AND stuck.bin_fill_pct > @Fill_threshold
AND stuck.type_code IN ('frame','sun')
AND NOT EXISTS (SELECT TOP 1 part_no FROM dbo.cvo_replenish_early_warning_tbl AS rewt
	 WHERE stuck.part_no = rewt.part_no AND stuck.location = rewt.location 
		AND stuck.bin_no = rewt.bin_no AND rewt.asofdate >= DATEADD(d,-1,GETDATE()) )



IF @@ROWCOUNT > 0
BEGIN

	INSERT dbo.cvo_replenish_early_warning_tbl
	        ( type_code ,
	          part_no ,
	          location ,
	          bin_no ,
	          replenish_min_lvl ,
	          replenish_max_lvl ,
	          inv_qty ,
	          alloc_qty ,
	          alloc_pct ,
	          bin_fill_pct ,
	          replen_qty ,
	          asofdate
	        )
		SELECT t.type_code ,
               t.part_no ,
               t.location ,
               t.bin_no ,
               t.replenish_min_lvl ,
               t.replenish_max_lvl ,
               t.inv_qty ,
               t.alloc_qty ,
               t.alloc_pct ,
               t.bin_fill_pct ,
               t.replen_qty ,
			   GETDATE() FROM #T AS t

-- set up email message to send
	SET @message = ''
	-- SELECT 'There are bins that are more than 50% allocated with inventory close to their replenish max level.'
	SET @subject = 'Bin Replenish Early Warning'
	SET @message = @message + '<H3>Allocated bins close to max replenish level'
              + '</H3><table width="100%" style="border:0;"><tr><td><table cellpadding="5" align="left" width="55%" style="border:0;">' +
              '<tr style="background:#025a89; color:#ffffff;" text-align="left"><th>type</th><th>Part #</th>' +
              '<th>location</th><th>bin</th><th>replen max</th><th>inv qty</th><th>alloc qty</th></tr>' +
              CAST(( SELECT td = type_code,       '',
                                  td = part_no, '',
                                  td = location, '',
                                  td = bin_no, '',
								  td = replenish_max_lvl, '',
								  td = inv_qty, '',
								  td = alloc_qty, ''
                           FROM #t
              ORDER BY id ASC
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    '</td></tr></table></table><BR><BR>' ;

	 SET @email_address = 'tgraziosi@cvoptical.com'
	 SET @subject = @subject + ' - TESTING'
	--SET @email_address = '#DCReplenEarlyWarning@cvoptical.com'

	EXEC @rc = msdb.dbo.sp_send_dbmail
				@recipients = @email_address,
				@body = @message, 
				@subject = @subject,
				@body_format = 'HTML',
				@profile_name = 'wms_1'

END

END

GO
GRANT EXECUTE ON  [dbo].[cvo_replenish_early_warning_sp] TO [public]
GO

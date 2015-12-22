SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- exec slpinvregbyterritoryuser_sp 'cvoptical\leeb', '1/1/2012', '1/31/2012'

CREATE proc [dbo].[SlpInvRegbyTerritoryUser_sp]
          @user varchar(1024),
          
       --@DateDocFrom Datetime,
       --@DateDocTo Datetime
                   
          @DateAppliedFrom Datetime,
          @DateAppliedTo Datetime
          
          
          --@DateShippedFrom Datetime,
          --@DateShippedTo Datetime
                   
          As
Begin
          --Print @DateAppliedFrom
          --Print @DateAppliedTo
          
          --Declare @DateDocFromJ bigint
          --Declare @DateDocToJ bigint
            
          --select @DateDocFromJ = datediff(day,'1/1/1950',convert(datetime,
          --convert(varchar( 8), (year(@DateDocFrom) * 10000) + (month(@DateDocFrom) * 100) + day(@DateDocFrom)))  ) + 711858
          --select @DateDocToJ = datediff(day,'1/1/1950',convert(datetime,
          --convert(varchar( 8), (year(@DateDocTo) * 10000) + (month(@DateDocTo) * 100) + day(@DateDocTo)))  ) + 711858

	      Declare @DateAppliedFromJ int
          Declare @DateAppliedToJ int
          
          select @DateAppliedFromJ = datediff(day,'1/1/1950',convert(datetime,
          convert(varchar( 8), (year(@DateAppliedFrom) * 10000) + (month(@DateAppliedFrom) * 100) + day(@DateAppliedFrom)))  ) + 711858
          select @DateAppliedToJ = datediff(day,'1/1/1950',convert(datetime,
          convert(varchar( 8), (year(@DateAppliedTo) * 10000) + (month(@DateAppliedTo) * 100) + day(@DateAppliedTo)))  ) + 711858

          
       --   Declare @DateShippedFromJ bigint
       --   Declare @DateShippedToJ bigint
          
       --   select @DateShippedFromJ = datediff(day,'1/1/1950',convert(datetime,
       --   convert(varchar( 8), (year(@DateShippedFrom) * 10000) + (month(@DateShippedFrom) * 100) + day(@DateShippedFrom)))  ) + 711858
       --   select @DateShippedToJ = datediff(day,'1/1/1950',convert(datetime,
       --   convert(varchar( 8), (year(@DateShippedTo) * 10000) + (month(@DateShippedTo) * 100) + day(@DateShippedTo)))  ) + 711858
          
          --Declare @TodayDateJ int
          
          --select @TodayDateJ = datediff(day,'1/1/1950',convert(datetime,
          --convert(varchar( 8), (year(GETDATE()) * 10000) + (month(GETDATE()) * 100) + day(GETDATE())))  ) + 711858
          
                  
          select salesperson,territory,cust_code,ship_to,name,order_no,ext,invoice_no,
		  
	     -- convert(varchar,dateadd(d,DATE_DOC-711858,'1/1/1950'),101) AS DATE_DOC,
	      InvoiceDate = 
	              CASE 
	                WHEN invoicedate=0 THEN convert(varchar, 0, 101)
	                   WHEN invoicedate=NULL THEN convert(varchar,null,101)
	                ELSE Convert(datetime,dateadd(d,invoicedate-711858,'1/1/1950'),101)
	               END,          
	     -- convert(varchar,dateadd(d,DATE_SHIPPED-711858,'1/1/1950'),101) AS DATE_SHIPPED, 
	      DateShipped = 
	              CASE 
	                WHEN DATESHIPPED=0 THEN convert(varchar, 0, 101)
	                   WHEN DATESHIPPED=NULL THEN convert(varchar,null,101)
	                ELSE Convert(datetime,dateadd(d,DATESHIPPED-711858,'1/1/1950'),101)
	               END,
		  OrderType, promo_id, level, type,amount, [comm%], [comm$], loc, salesperson_name, hiredate, draw_amount
          
          FROM
          CVO_commission_bldr_vw ir INNER JOIN f_get_terr_for_username(@user) tu 
            on ir.territory = tu.territory_code
          Where Dateshipped BETWEEN @DateAppliedFromJ AND @DateAppliedToJ
                                                        
          End
GO

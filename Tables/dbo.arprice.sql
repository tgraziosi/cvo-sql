CREATE TABLE [dbo].[arprice]
(
[timestamp] [timestamp] NOT NULL,
[price_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[best_price_flag] [smallint] NOT NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		arprice_del_trg		
Type:		Trigger
Description:	Deletes price code from cvo_comm_pclass
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	13/04/2011	Original Version
*/
CREATE TRIGGER [dbo].[arprice_del_trg] ON [dbo].[arprice]
FOR DELETE
AS
BEGIN
	DECLARE	@price_code	varchar(8)

	SET @price_code = ''
		
	-- Get the price_code to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@price_code = price_code
		FROM 
			deleted 
		WHERE
			price_code > @price_code
		ORDER BY 
			price_code

		IF @@RowCount = 0
			Break

		-- Delete record from cvo_comm_pclass 
		DELETE FROM cvo_comm_pclass WHERE price_code = @price_code

	END		
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		arprice_ins_trg		
Type:		Trigger
Description:	Adds price code to cvo_comm_pclass
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	13/04/2011	Original Version
*/
CREATE TRIGGER [dbo].[arprice_ins_trg] ON [dbo].[arprice]
FOR INSERT
AS
BEGIN
	DECLARE	@price_code	varchar(8)

	SET @price_code = ''
		
	-- Get the price_code to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@price_code = price_code
		FROM 
			inserted 
		WHERE
			price_code > @price_code
		ORDER BY 
			price_code

		IF @@RowCount = 0
			Break

		-- If the price code doesn't exist in cvo_comm_pclass then add it
		IF NOT EXISTS (SELECT 1 FROM cvo_comm_pclass WHERE price_code = @price_code)		
		BEGIN
			INSERT INTO cvo_comm_pclass(
				price_code)
			SELECT 
				@price_code	
		END

	END		
END


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_ARPrice_iu_trg] ON [dbo].[arprice] FOR insert,update
AS
begin

  DECLARE @nResult                    int, 
	  @vcCustomerPriceClass_ID    varchar(8), 
	  @last_CustomerPriceClass_ID varchar(8),  
	  @ddid                       varchar(32),
      @Sender             varchar(32)

  if exists(select * from master..sysprocesses 
	      where spid=@@SPID and program_name = 'Epicor EAI')
    return

  select @last_CustomerPriceClass_ID = ''
 select  @Sender = ddid
 from smcomp_vw

  while 1=1
  begin

    set rowcount 1
    select @vcCustomerPriceClass_ID = price_code, @ddid = ddid 
    from inserted
    where price_code > @last_CustomerPriceClass_ID
    order by price_code

    if @@ROWCOUNT <= 0 
      BREAK
    
    set rowcount 0

    IF @ddid IS NULL
    BEGIN
	SELECT @ddid = REPLACE(CONVERT(varchar(36),NEWID()),'-','')

	UPDATE arprice
    	SET    ddid = @ddid
    	WHERE  arprice.price_code = @vcCustomerPriceClass_ID
    END

    exec @nResult = EAI_Send_sp @type = 'CustomerPriceClass', @data = @ddid, @source = 'BO', @action = 1, @SenderID = @Sender

    select @last_CustomerPriceClass_ID = @vcCustomerPriceClass_ID
  end
end
GO
CREATE NONCLUSTERED INDEX [EAI_Integration] ON [dbo].[arprice] ([ddid]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arprice_ind_0] ON [dbo].[arprice] ([price_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arprice] TO [public]
GO
GRANT SELECT ON  [dbo].[arprice] TO [public]
GO
GRANT INSERT ON  [dbo].[arprice] TO [public]
GO
GRANT DELETE ON  [dbo].[arprice] TO [public]
GO
GRANT UPDATE ON  [dbo].[arprice] TO [public]
GO

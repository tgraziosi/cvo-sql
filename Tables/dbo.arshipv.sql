CREATE TABLE [dbo].[arshipv]
(
[timestamp] [timestamp] NOT NULL,
[ship_via_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_via_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_via_acct] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_ARShipv_iu_trg] ON [dbo].[arshipv] FOR insert,update
AS
begin

  DECLARE @nResult                int, 
	  @vcCarrier_ID           varchar(8), 
	  @last_Carrier_ID 	  varchar(8),  
	  @ddid                   varchar(32),
      @Sender                varchar(32)        

  if exists(select * from master..sysprocesses 
	      where spid=@@SPID and program_name = 'Epicor EAI')
    return

  select @last_Carrier_ID = ''
  select @Sender=ddid
  from smcomp_vw

  while 1=1
  begin

    set rowcount 1
    select @vcCarrier_ID = ship_via_code, @ddid = ddid 
    from inserted
    where ship_via_code > @last_Carrier_ID
    order by ship_via_code

    if @@ROWCOUNT <= 0 
      BREAK
    
    set rowcount 0

    IF @ddid IS NULL
    BEGIN
	SELECT @ddid = REPLACE(CONVERT(varchar(36),NEWID()),'-','')

	UPDATE arshipv
    	SET    ddid = @ddid
    	WHERE  arshipv.ship_via_code = @vcCarrier_ID
    END

    exec @nResult = EAI_Send_sp @type = 'Carrier', @data = @ddid, @source = 'BO', @action = 1, @SenderID = @Sender

    select @last_Carrier_ID = @vcCarrier_ID
  end
end
GO
CREATE NONCLUSTERED INDEX [arshipv_ind_2] ON [dbo].[arshipv] ([addr_sort1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arshipv_ind_3] ON [dbo].[arshipv] ([addr_sort2]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arshipv_ind_4] ON [dbo].[arshipv] ([addr_sort3]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [EAI_Integration] ON [dbo].[arshipv] ([ddid]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arshipv_ind_0] ON [dbo].[arshipv] ([ship_via_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arshipv_ind_1] ON [dbo].[arshipv] ([vendor_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arshipv] TO [public]
GO
GRANT SELECT ON  [dbo].[arshipv] TO [public]
GO
GRANT INSERT ON  [dbo].[arshipv] TO [public]
GO
GRANT DELETE ON  [dbo].[arshipv] TO [public]
GO
GRANT UPDATE ON  [dbo].[arshipv] TO [public]
GO

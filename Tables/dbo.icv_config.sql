CREATE TABLE [dbo].[icv_config]
(
[sequence_id] [int] NOT NULL,
[configuration_item_name] [char] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[configuration_int_value] [int] NOT NULL,
[configuration_text_value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_config] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_config] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_config] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_config] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_config] TO [public]
GO

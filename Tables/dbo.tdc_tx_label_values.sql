CREATE TABLE [dbo].[tdc_tx_label_values]
(
[module] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans_source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[input_prompt_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[input_prompt_desc] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_tx_label_values] ADD CONSTRAINT [PK_tdc_tx_label_values] PRIMARY KEY NONCLUSTERED  ([module], [trans], [trans_source], [input_prompt_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_tx_label_values] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_tx_label_values] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_tx_label_values] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_tx_label_values] TO [public]
GO

library(quantmod)
library(BatchGetSymbols)

# Fecha desde la que se piden los precios
fecha_inicio = "2000-01-01"

# Función para que devuelva úncimente el precio ajustado
yahoo_data <- function(ticker){
  res <- getSymbols(ticker, from=fecha_inicio,to=Sys.time(), auto.assign = FALSE)
  res  <- res[,6]
  colnames(res) <- ticker
  res
}

# Actuales 500 mejores acciones en S&P
sp500_tickers <- GetSP500Stocks()$Tickers
sp500_tickers <- gsub("\\.", "-", sp500_tickers) # hay que reemplazar . por -

# Descargar la info de las mejores 500 S&P
listaR_sp500 <- lapply(sp500_tickers, yahoo_data)
sp500 <- do.call(merge, listaR_sp500)


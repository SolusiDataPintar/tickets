package price

import "time"

type priceDeta struct {
	price  Price
	expire time.Time
}

type Price struct {
	Cardano PriceDetail `json:"cardano"`
}

type PriceDetail struct {
	Idr float64 `json:"idr"`
}

type PriceOne struct {
	Id    string  `json:"id"`
	Vs    string  `json:"vs"`
	Price float64 `json:"price"`
}

package cardano

import (
	"fmt"

	"github.com/LeonColt/ez"
)

func newErrorAssetNotFound(policyId, assetId string) *ez.Error {
	return &ez.Error{
		Code:    ez.ErrorCodeNotFound,
		Message: fmt.Sprintf("cardano asset with policy id %s and asset id %s was not found", policyId, assetId),
	}
}

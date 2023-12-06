package common

import (
	"crypto/sha256"
	"crypto/sha512"
	"encoding/hex"
	"fmt"
	"regexp"
)

const sha256RegexString = "^[A-Fa-f0-9]{64}$"
const sha512RegexString = "^[A-Fa-f0-9]{128}$"

func Sha256String(value string) (string, error) {
	hasher := sha256.New()
	_, err := hasher.Write([]byte(value))
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(hasher.Sum(nil)), nil
}

func Sha256Byte(value []byte) (string, error) {
	hasher := sha256.New()
	_, err := hasher.Write([]byte(value))
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(hasher.Sum(nil)), nil
}

func IsSHA256(hash string) bool {
	regex := regexp.MustCompile(sha256RegexString)
	return regex.MatchString(hash)
}

func ValidateSHA256(hash string) error {
	if IsSHA256(hash) {
		return nil
	} else {
		return fmt.Errorf("invalid hash:" + hash)
	}
}

func Sha512String(value string) (string, error) {
	hasher := sha512.New()
	_, err := hasher.Write([]byte(value))
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(hasher.Sum(nil)), nil
}

func Sha512Byte(value []byte) (string, error) {
	hasher := sha512.New()
	_, err := hasher.Write([]byte(value))
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(hasher.Sum(nil)), nil
}

func IsSHA512(hash string) bool {
	regex := regexp.MustCompile(sha512RegexString)
	return regex.MatchString(hash)
}

func ValidateSHA512(hash string) error {
	if IsSHA256(hash) {
		return nil
	} else {
		return fmt.Errorf("invalid hash:" + hash)
	}
}

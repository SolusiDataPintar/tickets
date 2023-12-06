String convertIpfsToHttp(final String ipfs) =>
    ipfs.replaceFirst("ipfs://", "https://cf-ipfs.com/ipfs/");

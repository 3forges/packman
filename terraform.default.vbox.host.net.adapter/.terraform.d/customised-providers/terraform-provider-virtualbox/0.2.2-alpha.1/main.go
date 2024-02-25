// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
package main

import (
	"github.com/hashicorp/terraform-plugin-sdk/plugin"
	"github.com/terra-farm/terraform-provider-virtualbox/virtualbox"
)

func main() {
	plugin.Serve(&plugin.ServeOpts{
		ProviderFunc: virtualbox.Provider,
	})
}

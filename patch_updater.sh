#!/bin/bash
sed -i.bak 's/pub async fn check_and_update(tx: Option<broadcast::Sender<String>>)/pub async fn check_update(tx: Option<broadcast::Sender<String>>) -> Option<String>/' ea-server/src/updater.rs

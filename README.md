# cmp-symfony

[nvim-cmp](https://github.com/hrsh7th/nvim-cmp) source for many
Symfony completions.

## Required deps
- [fd](https://github.com/sharkdp/fd) for twig templates
- [jq](https://github.com/jqlang/jq) for form options
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) for form options (with PHP parser)

## Global setup

```lua
require('cmp').setup({
  sources = {
    { name = 'form_options' },
  },
})
```

## Available sources

### Form options
Form option completion.

#### Prerequisite
The completion is based on a file named `autocomplete_form_type.json`
at the root of the project. It consists of a JSON array for each
FormType as key and all available options as values.  
This file is obtained iterating over the results of:  
```bash
bin/console debug:form --format json # gets all form types
bin/console debug:form --format json ChoiceType # for each for type
```

Here is the script I'm using to create this file:  
<details>
<summary>View script</summary>

```bash  
#!/usr/bin/env bash

function create_json() {
    echo "$1" | jq -c '{
        (."class" | split("\\") | last): (
            [
                .class as $class |
                (.options.own // [] | map({(.): $class}) | add) as $own |
                (.options.overridden // {} | to_entries | map({key: .value[], value: .key}) | from_entries) as $overridden |
                (.options.parent // {} | to_entries | map({key: .value[], value: .key}) | from_entries) as $parent |
                (.options.extension // {} | to_entries | map({key: .value[], value: .key}) | from_entries) as $extension |
                $own + $overridden + $parent + $extension
            ] | add
        )
    }'
}

json=$(docker compose run --rm franken-cli bin/console debug:form --format json)

echo "" > /tmp/autocomplete_form_type.json

builtin_types=$(echo "$json" | jq -r ".builtin_form_types[]")
service_types=$(echo "$json" | jq -r ".service_form_types[]")

builtin_types_count=$(echo "$builtin_types" | wc -l)
service_types_count=$(echo "$service_types" | wc -l)

counter=0
echo "[INFO] Creating builtin types"
for builtin_type in $builtin_types; do
    counter=$((counter+1))
    echo "$counter/$builtin_types_count: $builtin_type"
    json=$(docker compose exec franken bin/console debug:form --format json "$builtin_type")

    create_json "$json" >> /tmp/autocomplete_form_type.json
done

counter=0
echo "[INFO] Creating service types"
for service_type in $service_types; do
    counter=$((counter+1))
    echo "$counter/$service_types_count: $service_type"
    json=$(docker compose exec franken bin/console debug:form --format json "$service_type")

    create_json "$json" >> /tmp/autocomplete_form_type.json
done

jq --slurp 'add' /tmp/autocomplete_form_type.json > ./autocomplete_form_type.json
```
</details>

This is rather hard to maintain, so duplicated FormType are not preserved.

#### Triggers

The plugin is activated for `php` filetypes.  
The trigger character is a single quote, and the current buffer must `extends AbstractType`.  
The completion is triggered only on the left side of `=>`.

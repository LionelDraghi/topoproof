# Translation

`translate` applies an exact displacement to a point: `topoproof translate X Y Z DX DY DZ`.
The canonical result is `point X Y Z`.

## Scenario: translate command-line values
- When I run `../bin/topoproof translate 10 -20 30 5 7 -9`
- Then the output is `point 15 -13 21`
- And there is no error

## Scenario: reject an unrepresentable result
- When I run `../bin/topoproof translate 1000000000 0 0 1 0 0`
- Then the output is `error: translation is not representable`
- And there is an error

## Scenario: write the result to a file
- Given there is no file `translation.out`
- When I successfully run `../bin/topoproof translate 1 2 3 4 5 6 --output translation.out`
- Then the `translation.out` file contains `point 5 7 9`

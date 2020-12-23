/*
 This is included in script.yaml
 Original Source is from:
   * https://dgraph.io/docs/graphql/lambda/query/
   * https://dgraph.io/docs/graphql/lambda/mutation/
*/

async function authorsByName({args, dql}) {
    const results = await dql.query(`query queryAuthor($name: string) {
        queryAuthor(func: type(Author)) @filter(eq(Author.name, $name)) {
            name: Author.name
            dob: Author.dob
            reputation: Author.reputation
        }
    }`, {"$name": args.name})
    return results.data.queryAuthor
}

async function newAuthor({args, graphql}) {
    // lets give every new author a reputation of 3 by default
    const results = await graphql(`mutation ($name: String!) {
        addAuthor(input: [{name: $name, reputation: 3.0 }]) {
            author {
                id
                reputation
            }
        }
    }`, {"name": args.name})
    return results.data.addAuthor.author[0].id
}

self.addGraphQLResolvers({
    "Query.authorsByName": authorsByName,
    "Mutation.newAuthor": newAuthor
})
